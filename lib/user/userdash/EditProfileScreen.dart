import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // For displaying residence details (read-only)
  String _flatNumber = "";
  String _societyName = "";
  String _state = "";
  String _city = "";

  File? _profileImage;
  bool _isLoading = true;
  bool _emailChanged = false;
  bool _phoneChanged = false;
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;
  String? _verificationId;
  String? _originalPhone;
  String? _originalEmail;
  bool _isOtpSent = false;
  int _resendTimer = 60;
  Timer? _timer;
  bool _canResendOtp = false;

  // Define theme colors
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color secondaryBlue = Color(0xFF64B5F6);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color accentYellow = Color(0xFFFFD54F);
  static const Color backgroundWhite = Color(0xFFF5F7FA);
  static const Color errorRed = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }

    setState(() {
      _canResendOtp = false;
      _resendTimer = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendTimer > 0) {
            _resendTimer--;
          } else {
            _canResendOtp = true;
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // First try with phone number as document ID
        String phoneNumber = currentUser.phoneNumber ?? '';
        DocumentSnapshot? userDoc;

        if (phoneNumber.isNotEmpty) {
          userDoc = await _firestore.collection('customers').doc(phoneNumber).get();
        }

        // If no document found with phone, try with UID
        if (userDoc == null || !userDoc.exists) {
          userDoc = await _firestore.collection('customers').doc(currentUser.uid).get();
        }

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          Map<String, dynamic> residenceDetails = userData['residenceDetails'] ?? {};

          setState(() {
            _nameController.text = userData['name'] ?? '';
            _emailController.text = userData['email'] ?? '';

            // Format phone number properly
            String phone = userData['phone'] ?? '';
            if (phone.startsWith('+91')) {
              _phoneController.text = phone.replaceAll('+91', '');
            } else {
              _phoneController.text = phone;
            }

            // Set residence details (read-only)
            _flatNumber = residenceDetails['flatNumber'] ?? '';
            _societyName = residenceDetails['societyName'] ?? '';
            _state = residenceDetails['state'] ?? '';
            _city = residenceDetails['city'] ?? '';

            _originalPhone = _phoneController.text;
            _originalEmail = _emailController.text;
          });
        } else {
          _showSnackbar('User profile not found');
        }
      }
    } catch (e) {
      _showSnackbar('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackbar("Please fill all required fields");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Important: Find the existing document first
        DocumentSnapshot? userDoc;
        String? documentId;

        // Try to find document by phone number
        if (currentUser.phoneNumber != null && currentUser.phoneNumber!.isNotEmpty) {
          userDoc = await _firestore.collection('customers').doc(currentUser.phoneNumber).get();
          if (userDoc.exists) {
            documentId = currentUser.phoneNumber;
          }
        }

        // If not found by phone, try with UID
        if (documentId == null) {
          userDoc = await _firestore.collection('customers').doc(currentUser.uid).get();
          if (userDoc.exists) {
            documentId = currentUser.uid;
          } else {
            // If still not found, default to UID (most secure)
            documentId = currentUser.uid;
          }
        }

        // Prepare updates - only include fields that user can modify
        Map<String, dynamic> userData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': '+91${_phoneController.text.trim()}',
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        // Determine if we need to create or update
        if (userDoc != null && userDoc.exists) {
          await _firestore.collection('customers').doc(documentId).update(userData);
        } else {
          await _firestore.collection('customers').doc(documentId).set(userData, SetOptions(merge: true));
        }

        _showSnackbar('Profile updated successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackbar('Error saving profile: $e');
      print('Detailed error: $e'); // Add this for debugging
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });

        // Here you would upload the image to storage and save the URL
        // For simplicity, we're just keeping the file reference
      }
    } catch (e) {
      _showSnackbar('Error selecting image: ${e.toString()}');
    }
  }

  Future<void> _sendOtp(String type) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (type == "phone") {
        String phoneNumber = '+91${_phoneController.text.trim()}';

        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto verification completed (mostly on Android)
            await _auth.signInWithCredential(credential);
            setState(() {
              _isPhoneVerified = true;
            });
          },
          verificationFailed: (FirebaseAuthException e) {
            _showSnackbar("Verification Failed: ${e.message}");
          },
          codeSent: (String vId, int? resendToken) {
            setState(() {
              _verificationId = vId;
              _isOtpSent = true;
            });
            _startResendTimer();
          },
          codeAutoRetrievalTimeout: (String vId) {},
        );
      } else if (type == "email") {
        // Simulate email verification (in a real app, you'd send an actual email)
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _isOtpSent = true;
        });
        _startResendTimer();
      }
    } catch (e) {
      _showSnackbar("An error occurred: ${e.toString()}");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyOtp(String type) async {
    if (_verificationId == null || _otpController.text.trim().isEmpty) {
      _showSnackbar("Please enter the OTP");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (type == "phone") {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: _otpController.text.trim(),
        );
        await _auth.signInWithCredential(credential);
        setState(() {
          _isPhoneVerified = true;
        });
      } else {
        // For email, just simulate verification
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _isEmailVerified = true;
        });
      }

      _showSnackbar("OTP Verified Successfully");
      _otpController.clear();
    } on FirebaseAuthException catch (e) {
      _showSnackbar("OTP Verification Failed: ${e.message}");
    } catch (e) {
      _showSnackbar("An error occurred during verification");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryBlue,
      ),
    );
  }

  // Helper method to build read-only info rows
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? "Not provided" : value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Divider(height: 8),
        ],
      ),
    );
  }

  Widget _buildOtpVerificationSection(String type) {
    if (!_isOtpSent) return const SizedBox();

    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          "Enter OTP sent to your ${type == 'phone' ? 'mobile' : 'email'}",
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Pinput(
          controller: _otpController,
          length: 6,
          defaultPinTheme: PinTheme(
            width: 40,
            height: 45,
            textStyle: const TextStyle(fontSize: 18),
            decoration: BoxDecoration(
              border: Border.all(color: primaryBlue),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _canResendOtp && !_isLoading
                  ? () => _sendOtp(type)
                  : null,
              child: Text(
                _canResendOtp ? 'Resend OTP' : 'Resend in $_resendTimer sec',
                style: TextStyle(
                  color: _canResendOtp ? primaryBlue : Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => _verifyOtp(type),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Verify'),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black54),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryBlue),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Picture
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: lightBlue,
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : const AssetImage("assets/images/imagefixify.png") as ImageProvider,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: _pickImage,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Personal Information
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Personal Information",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration('Full Name'),
                        validator: (value) => value?.isEmpty ?? true ? 'Please enter name' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: _inputDecoration('Email'),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) {
                          if (value != _originalEmail) {
                            setState(() {
                              _emailChanged = true;
                              _isEmailVerified = false;
                            });
                          } else {
                            setState(() {
                              _emailChanged = false;
                            });
                          }
                        },
                      ),
                      if (_emailChanged && !_isEmailVerified) ...[
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _sendOtp('email'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentYellow,
                            foregroundColor: Colors.black87,
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          child: const Text('Verify Email'),
                        ),
                        _buildOtpVerificationSection('email'),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: _inputDecoration('Mobile Number'),
                        keyboardType: TextInputType.phone,
                        onChanged: (value) {
                          if (value != _originalPhone) {
                            setState(() {
                              _phoneChanged = true;
                              _isPhoneVerified = false;
                            });
                          } else {
                            setState(() {
                              _phoneChanged = false;
                            });
                          }
                        },
                      ),
                      if (_phoneChanged && !_isPhoneVerified) ...[
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => _sendOtp('phone'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentYellow,
                            foregroundColor: Colors.black87,
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          child: const Text('Verify Phone'),
                        ),
                        _buildOtpVerificationSection('phone'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Residence Information (Read-only)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Residence Information",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: lightBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              "Read-only",
                              style: TextStyle(
                                fontSize: 12,
                                color: primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow("State", _state),
                      _buildInfoRow("City", _city),
                      _buildInfoRow("Society Name", _societyName),
                      _buildInfoRow("Flat/House Number", _flatNumber),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveProfileChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    "Save Changes",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cancel Button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: primaryBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}