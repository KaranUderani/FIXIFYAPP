import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pinput/pinput.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  // States
  bool isLoading = true;
  bool isEditing = false;
  bool isPhoneEditing = false;
  bool isOtpSent = false;
  String? verificationId;
  String verificationStatus = "NOT-VERIFIED!";
  bool isEditingPhone = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _saveChanges() async {
    bool needsUpdate = false;

    // Check if name needs to be updated
    if (isEditing && nameController.text.trim().isNotEmpty) {
      needsUpdate = true;
      await _updateUserData();
    }

    // Check if phone needs to be updated
    if (isPhoneEditing && isOtpSent && otpController.text.length == 6) {
      needsUpdate = true;
      await verifyOtp();
    }

    if (needsUpdate) {
      _showSnackbar('Changes saved successfully!');
    }

    if (!isLoading) {
      Navigator.pop(context);
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String phoneNumber = currentUser.phoneNumber ?? '';

        if (phoneNumber.isNotEmpty) {
          DocumentSnapshot userDoc = await _firestore
              .collection('users')
              .doc(phoneNumber)
              .get();

          if (userDoc.exists) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

            setState(() {
              nameController.text = userData['name'] ?? '';
              phoneController.text = phoneNumber.replaceAll('+91', '');

              // Clean and standardize verification status
              String rawStatus = userData['verificationStatus'] ?? 'not-verified';
              if (rawStatus == 'pending') {
                verificationStatus = 'PENDING!';
              } else if (rawStatus == 'verified') {
                verificationStatus = 'VERIFIED!';
              } else {
                verificationStatus = 'NOT-VERIFIED!';
              }

              // Debug output
              print('Loaded verification status: "$verificationStatus"');
            });
          }
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      _showSnackbar('Error loading user data. Please try again.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<bool> _updateUserData() async {
    if (nameController.text.trim().isEmpty) {
      _showSnackbar('Name cannot be empty');
      return false;
    }

    setState(() {
      isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String phoneNumber = currentUser.phoneNumber ?? '';

        if (phoneNumber.isNotEmpty) {
          await _firestore.collection('users').doc(phoneNumber).update({
            'name': nameController.text.trim(),
          });

          _showSnackbar('Profile updated successfully!');
          setState(() {
            isEditing = false;
          });
          return true;
        }
      }
      // Add this return statement to handle the case when the user is null or phone is empty
      return false;
    } catch (e) {
      print('Error updating user data: $e');
      _showSnackbar("Error updating profile. Please try again. ${e.toString()}");
      return false;
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Update phone number functions
  Future<void> sendOtp() async {
    if (phoneController.text.length != 10) {
      _showSnackbar("Enter a valid 10-digit phone number");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String phoneNumber = '+91${phoneController.text.trim()}';

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto verification completed (mostly on Android)
        },
        verificationFailed: (FirebaseAuthException e) {
          _showSnackbar("Verification Failed: ${e.message}");
        },
        codeSent: (String vId, int? resendToken) {
          setState(() {
            verificationId = vId;
            isOtpSent = true;
            isLoading = false;
          });
          _showSnackbar("OTP sent successfully!");
        },
        codeAutoRetrievalTimeout: (String vId) {},
      );
    } catch (e) {
      _showSnackbar("An error occurred. Please try again.");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> verifyOtp() async {
    setState(() {
      isLoading = true;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otpController.text.trim(),
      );

      // Re-authenticate user with the new phone number
      await _auth.currentUser?.updatePhoneNumber(credential);

      // Update phone number in Firestore
      String newPhoneNumber = '+91${phoneController.text.trim()}';
      User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        String oldPhoneNumber = currentUser.phoneNumber ?? '';

        // Get the user data from old document
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(oldPhoneNumber)
            .get();

        if (userDoc.exists) {
          // Create new document with updated phone number
          await _firestore.collection('users').doc(newPhoneNumber).set(userDoc.data() as Map<String, dynamic>);

          // Delete old document
          await _firestore.collection('users').doc(oldPhoneNumber).delete();
        }
      }

      _showSnackbar("Phone number updated successfully!");
      setState(() {
        isPhoneEditing = false;
        isOtpSent = false;
      });
    } catch (e) {
      _showSnackbar("Verification failed: ${e.toString()}");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showVerificationScreen() {
    print('Opening verification screen. Current status: $verificationStatus');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddressProofScreen()),
    ).then((_) {
      _loadUserData(); // Refresh data when returning
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug output in build method
    print('Building UI with verification status: "$verificationStatus"');

    return Scaffold(
      backgroundColor: Colors.yellow[100],
      appBar: AppBar(
        backgroundColor: Colors.yellow[100],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Image.asset(
                      'assets/images/imagefixify.png',
                      height: 60,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Full Name', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameController,
                          enabled: isEditing,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter your name',
                          ),
                          style: TextStyle(fontSize: 16),
                          onSubmitted: (value) {
                            if (isEditing) {
                              _updateUserData();
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isEditing ? Icons.save : Icons.edit,
                          color: Colors.grey[700],
                        ),
                        onPressed: () {
                          if (isEditing) {
                            _updateUserData();
                          } else {
                            setState(() {
                              isEditing = true;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  Divider(),
                  SizedBox(height: 10),
                  Text('Mobile Number', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Text("+91 ", style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: isPhoneEditing
                            ? TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Enter phone number',
                          ),
                          style: TextStyle(fontSize: 16),
                        )
                            : Text(
                          phoneController.text,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isPhoneEditing ? Icons.close : Icons.edit,
                          color: Colors.grey[700],
                        ),
                        onPressed: () {
                          setState(() {
                            isPhoneEditing = !isPhoneEditing;
                            isOtpSent = false;
                          });
                        },
                      ),
                    ],
                  ),
                  if (isPhoneEditing && !isOtpSent)
                    Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: ElevatedButton(
                        onPressed: sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          minimumSize: Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Send OTP',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  if (isPhoneEditing && isOtpSent)
                    Column(
                      children: [
                        SizedBox(height: 20),
                        Text(
                          'Enter OTP sent to +91 ${phoneController.text}',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 10),
                        Pinput(
                          controller: otpController,
                          length: 6,
                          defaultPinTheme: PinTheme(
                            width: 50,
                            height: 50,
                            textStyle: TextStyle(fontSize: 20),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            minimumSize: Size(double.infinity, 45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Verify OTP',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  Divider(),
                  SizedBox(height: 10),
                  Text('Verification', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        verificationStatus,
                        style: TextStyle(
                          fontSize: 16,
                          color: verificationStatus == 'VERIFIED!'
                              ? Colors.green
                              : verificationStatus == 'PENDING!'
                              ? Colors.orange
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: verificationStatus == 'NOT-VERIFIED!'
                            ? () {
                          print('Verify button pressed');
                          _showVerificationScreen();
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: verificationStatus == 'NOT-VERIFIED!' ? Colors.green : Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Verify Now',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: isLoading ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Save changes',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddressProofScreen extends StatefulWidget {
  const AddressProofScreen({Key? key}) : super(key: key);

  @override
  _AddressProofScreenState createState() => _AddressProofScreenState();
}

class _AddressProofScreenState extends State<AddressProofScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isFileUploaded = false;
  bool isLoading = false;
  File? addressProof;
  String? addressProofBase64;
  bool isChecked = false;

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        // File size validation
        int fileSizeInBytes = await imageFile.length();
        if (fileSizeInBytes > 5 * 1024 * 1024) { // 5MB limit
          _showSnackbar("Image size should be less than 5MB");
          return;
        }

        List<int> imageBytes = await imageFile.readAsBytes();
        String base64Image = base64Encode(imageBytes);

        setState(() {
          addressProof = imageFile;
          addressProofBase64 = base64Image;
          isFileUploaded = true;
        });

        _showSnackbar("Image uploaded successfully!");
      }
    } catch (e) {
      _showSnackbar("Error uploading image: ${e.toString()}");
    }
  }

  Future<void> _submitVerification() async {
    if (!isFileUploaded || !isChecked) {
      _showSnackbar("Please upload document and accept the terms");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String phoneNumber = currentUser.phoneNumber ?? '';

        if (phoneNumber.isNotEmpty) {
          await _firestore.collection('users').doc(phoneNumber).update({
            'addressProof': addressProofBase64,
            'verificationStatus': 'pending',
            'verificationTimestamp': FieldValue.serverTimestamp(),
          });

          _showSnackbar('Verification submitted successfully!');
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _showSnackbar("Error submitting verification: ${e.toString()}");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[100],
      appBar: AppBar(
        backgroundColor: Colors.yellow[100],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Text(
                'UPLOAD ADDRESS PROOF',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Please upload any of your address proof below for completing your Verification',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Text(
                      'AADHAR CARD/VOTER ID/ELECTRICITY BILL',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 15),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.upload, color: Colors.blue[800]),
                      label: Text('Upload +'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue[800],
                        side: BorderSide(color: Colors.blue[800]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    if (isFileUploaded && addressProof != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Image.file(
                              addressProof!,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.cancel,
                                color: Colors.red,
                                size: 28,
                              ),
                              onPressed: () {
                                setState(() {
                                  addressProof = null;
                                  addressProofBase64 = null;
                                  isFileUploaded = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Checkbox(
                    value: isChecked,
                    onChanged: (value) {
                      setState(() {
                        isChecked = value!;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(
                      'I hereby agree that the above document belongs to me and voluntarily give my consent to Fixify/parent/water Capital Pvt Ltd (Wint Wealth) to utilize it as my address proof for KYC on purpose only',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: isLoading ? null : _submitVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                  'Submit for verification',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'verified partners get listed as VERIFIED\nusers trust verified partners more for services',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}