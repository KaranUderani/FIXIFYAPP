import 'package:flutter/material.dart';
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

  // User details
  String _flatNumber = "";
  String _societyName = "";
  String _state = "";
  String _city = "";

  bool _isLoading = true;
  bool _phoneChanged = false;
  bool _isPhoneVerified = true;
  String? _verificationId;
  String? _originalPhone;
  String? _originalEmail;
  bool _isOtpSent = false;
  int _resendTimer = 60;
  Timer? _timer;
  bool _canResendOtp = false;
  bool _isAdmin = false;
  String? _adminId;

  // Theme colors
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
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

  // Consistent function to retrieve user document
  Future<DocumentSnapshot?> getUserDocument() async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return null;

    String phoneNumber = currentUser.phoneNumber ?? '';

    if (phoneNumber.isNotEmpty) {
      // Remove +91 prefix if present
      String documentId = phoneNumber.replaceAll('+91', '');

      // Try direct document access first
      DocumentSnapshot directDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(documentId)
          .get();

      if (directDoc.exists) {
        return directDoc;
      }

      // If direct access fails, try querying by phone field
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .where('phone', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first;
      }
    }

    return null;
  }
  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      DocumentSnapshot? userDoc = await getUserDocument();

      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Get phone number from Firebase Auth
        String? phoneNumber = currentUser.phoneNumber;
        if (phoneNumber != null) {
          _originalPhone = phoneNumber.replaceAll('+91', '');
          _phoneController.text = _originalPhone!;
        }
      }

      if (userDoc != null && userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

        // Debug output to check what fields are available
        print('User data fields: ${userData.keys.join(', ')}');

        // Load basic profile info
        setState(() {
          _nameController.text = userData['name']?.toString() ?? '';
          _emailController.text = userData['email']?.toString() ?? '';
          _originalEmail = userData['email']?.toString();
          _isAdmin = userData['isAdmin'] ?? false;
          _adminId = userData['adminId']?.toString();
        });

        // Load residence details with flexible field access
        if (userData.containsKey('residenceDetails')) {
          Map<String, dynamic> residenceDetails =
          userData['residenceDetails'] as Map<String, dynamic>;

          // Debug output for residence details
          print('Residence details fields: ${residenceDetails.keys.join(', ')}');

          setState(() {
            _flatNumber = residenceDetails['flatNumber']?.toString() ?? '';

            // Try both field names
            _societyName = residenceDetails['societyName']?.toString() ??
                residenceDetails['society']?.toString() ?? '';

            _city = residenceDetails['city']?.toString() ?? '';
            _state = residenceDetails['state']?.toString() ?? '';
          });
        }
      } else {
        _showSnackbar('User profile not found. Please create a new profile.');
      }
    } catch (e) {
      print('Error loading profile data: $e');
      _showSnackbar('Error loading profile data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackbar("Please fill all required fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String phoneNumber = _phoneController.text.trim();
        String formattedPhone = '+91$phoneNumber';

        // Get the actual document ID first
        DocumentSnapshot? userDoc = await getUserDocument();
        if (userDoc == null) {
          throw Exception("User document not found");
        }

        String documentId = userDoc.id; // This gets the actual Firestore document ID

        // Prepare update data
        Map<String, dynamic> updateData = {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': formattedPhone, // Make sure phone is stored with country code
          'isAdmin': _isAdmin,
          'adminId': _adminId,
          'residenceDetails': {
            'flatNumber': _flatNumber,
            'societyName': _societyName,
            'city': _city,
            'state': _state,
          },
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        // Handle phone number change if needed
        if (phoneNumber != _originalPhone && _isPhoneVerified) {
          // First create new document with new phone
          await _firestore.collection('customers').doc(phoneNumber).set(updateData);

          // Then update the Firebase Auth phone number
          await currentUser.updatePhoneNumber(
            PhoneAuthProvider.credential(
              verificationId: _verificationId!,
              smsCode: _otpController.text.trim(),
            ),
          );

          // Delete old document only after successful auth update
          await _firestore.collection('customers').doc(documentId).delete();

          _originalPhone = phoneNumber;
        } else {
          // Just update the existing document using its actual ID
          await _firestore.collection('customers').doc(documentId).update(updateData);

          // Add detailed logging
          print("Document updated successfully: $documentId");
        }

        _showSnackbar('Profile updated successfully');
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
      }
      _showSnackbar('Error saving profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);

    try {
      String phoneNumber = '+91${_phoneController.text.trim()}';

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          setState(() => _isPhoneVerified = true);
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
    } catch (e) {
      _showSnackbar("An error occurred: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null || _otpController.text.trim().isEmpty) {
      _showSnackbar("Please enter the OTP");
      return;
    }

    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otpController.text.trim(),
      );

      await _auth.signInWithCredential(credential);
      setState(() => _isPhoneVerified = true);
      _showSnackbar("Phone number verified successfully");
      _otpController.clear();
    } on FirebaseAuthException catch (e) {
      _showSnackbar("OTP Verification Failed: ${e.message}");
    } catch (e) {
      _showSnackbar("An error occurred during verification");
    } finally {
      setState(() => _isLoading = false);
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

  Widget _buildOtpVerificationSection() {
    if (!_isOtpSent) return const SizedBox();

    return Column(
      children: [
        const SizedBox(height: 16),
        const Text(
          "Enter OTP sent to your mobile",
          style: TextStyle(fontSize: 14, color: Colors.black54),
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
              onPressed: _canResendOtp && !_isLoading ? _sendOtp : null,
              child: Text(
                _canResendOtp ? 'Resend OTP' : 'Resend in $_resendTimer sec',
                style: TextStyle(
                  color: _canResendOtp ? primaryBlue : Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _verifyOtp,
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

  Widget _buildResidenceInfoSection() {
    return Card(
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            _buildInfoRow("Flat/House Number", _flatNumber),
            _buildInfoRow("Society Name", _societyName),
            _buildInfoRow("City", _city),
            _buildInfoRow("State", _state),
          ],
        ),
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
        iconTheme: const IconThemeData(color: primaryBlue),
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
                    backgroundImage: const AssetImage("assets/images/imagefixify.png") as ImageProvider,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 20),
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
                      ),
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
                              _isPhoneVerified = true;
                            });
                          }
                        },
                      ),
                      if (_phoneChanged && !_isPhoneVerified) ...[
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _sendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentYellow,
                            foregroundColor: Colors.black87,
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          child: const Text('Verify Phone'),
                        ),
                        _buildOtpVerificationSection(),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Residence Information
              _buildResidenceInfoSection(),
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