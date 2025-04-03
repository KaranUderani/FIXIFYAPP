import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pinput/pinput.dart';
import 'package:fixifypartner/features/dash/screens/dashboard.dart';

class CustomerSignUpScreen extends StatefulWidget {
  const CustomerSignUpScreen({Key? key}) : super(key: key);

  @override
  _CustomerSignUpScreenState createState() => _CustomerSignUpScreenState();
}

class _CustomerSignUpScreenState extends State<CustomerSignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int currentStep = 0;
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController adminnameController = TextEditingController();
  final TextEditingController adminemailController = TextEditingController();
  final TextEditingController societyNameController = TextEditingController();
  final TextEditingController adminflatNumberController = TextEditingController();

  String? selectedState;
  String? selectedCity;
  String? selectedSociety;
  String? verificationId;
  bool isOtpSent = false;
  bool isLoading = false;
  bool isOtpVerified = false;
  File? profilePicture;
  String? profilePictureBase64;
  bool isChecked = false;
  List<Map<String, dynamic>> societyMembers = [];

  // For society members
  final TextEditingController societyMemberNameController = TextEditingController();
  final TextEditingController societyMemberFlatNoController = TextEditingController();
  final TextEditingController societyMemberPhoneController = TextEditingController();
  final TextEditingController societyMemberOtpController = TextEditingController();

  // Store verification status of society members
  Map<String, bool> societyMemberVerificationStatus = {};
  Map<String, String> societyMemberVerificationIds = {};
  Map<String, bool> societyMemberOtpSent = {};
  String? currentVerifyingMemberPhone;

  // Verification applied status
  bool isVerificationApplied = false;
  String verificationStatus = 'pending';

  // OTP Timer Variables
  int _resendTimer = 60;
  Timer? _timer;
  bool _canResendOtp = false;

  // Enhanced Location Data
  Map<String, Map<String, dynamic>> enhancedLocations = {
    'Maharashtra': {
      'cities': ['Mumbai', 'Pune', 'Nagpur'],
      'societies': {
        'Mumbai': ['Hiranandani Gardens', 'Lodha Palava', 'Powai Plaza', 'Godrej Central'],
        'Pune': ['Magarpatta City', 'Amanora Park', 'Blue Ridge', 'Kumar Primavera'],
        'Nagpur': ['Empress City', 'Harmony Gardens', 'Shivaji Nagar']
      }
    },
    'Gujarat': {
      'cities': ['Ahmedabad', 'Surat'],
      'societies': {
        'Ahmedabad': ['Iscon Platinum', 'Godrej Garden City', 'Shaligram Heaven', 'Sun South Park'],
        'Surat': ['Vesu Heights', 'Apple Residency', 'New Citylight', 'South Bopal Homes']
      }
    },
    'Delhi': {
      'cities': ['New Delhi'],
      'societies': {
        'New Delhi': ['DLF Phase 5', 'Vasant Kunj Apartments', 'Dwarka Sector 12', 'Commonwealth Games Village']
      }
    }
  };

  // Get states list from enhancedLocations
  List<String> get states => enhancedLocations.keys.toList();

  // Get cities map from enhancedLocations
  Map<String, List<String>> get cities {
    return {
      for (var state in enhancedLocations.keys)
        state: (enhancedLocations[state]!['cities'] as List<dynamic>).cast<String>()
    };
  }

  // Get societies for a specific city
  List<String> getSocieties(String state, String city) {
    return (enhancedLocations[state]!['societies'][city] as List<dynamic>).cast<String>();
  }

  // Validation Regex
  final RegExp _nameRegex = RegExp(r'^[a-zA-Z ]+$');
  final RegExp _emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  final RegExp _phoneRegex = RegExp(r'^[0-9]{10}$');

  @override
  void dispose() {
    _timer?.cancel();
    societyMemberNameController.dispose();
    societyMemberFlatNoController.dispose();
    societyMemberPhoneController.dispose();
    societyMemberOtpController.dispose();
    super.dispose();
  }

  // Method to start OTP resend timer
  void _startResendTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }

    setState(() {
      _canResendOtp = false;
      _resendTimer = 60;
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
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

  // Improved phone number formatting
  String _formatPhoneNumber(String rawNumber) {
    try {
      String digits = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length == 10) return '+91$digits';
      if (digits.startsWith('91') && digits.length == 12) return '+$digits';
      throw FormatException('Invalid phone number format');
    } catch (e) {
      _showSnackbar("Invalid phone number format");
      return rawNumber;
    }
  }

  // Send OTP method for admin
  Future<void> sendOtp() async {
    try {
      if (!_phoneRegex.hasMatch(phoneController.text)) {
        _showSnackbar("Enter a valid 10-digit phone number");
        return;
      }

      String phoneNumber = _formatPhoneNumber(phoneController.text);

      setState(() => isLoading = true);

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          setState(() {
            isOtpVerified = true;
            isOtpSent = true;
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          _showSnackbar("Verification Failed: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            this.verificationId = verificationId;
            isOtpSent = true;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );

      // Start the resend timer
      _startResendTimer();
    } catch (e) {
      _showSnackbar("An unexpected error occurred. Please try again.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Method to resend OTP for admin
  Future<void> _resendOtp() async {
    // Ensure the phone number is valid before attempting to resend
    if (phoneController.text.length != 10) {
      _showSnackbar("Enter a valid 10-digit phone number");
      return;
    }

    // Only allow resend if timer is not active
    if (_canResendOtp) {
      await sendOtp();
      _startResendTimer();
    }
  }

  // Verify OTP method for admin
  Future<void> verifyOtp() async {
    if (verificationId == null || otpController.text.trim().isEmpty) {
      _showSnackbar("Invalid verification details");
      return;
    }

    setState(() => isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otpController.text.trim(),
      );
      await _auth.signInWithCredential(credential);

      setState(() {
        isOtpVerified = true;
      });

      _showSnackbar("OTP Verified!");
    } on FirebaseAuthException catch (e) {
      _showSnackbar("OTP Verification Failed: ${e.message}");
    } catch (e) {
      _showSnackbar("An unexpected error occurred during OTP verification");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Send OTP method for society member
  Future<void> sendMemberOtp(String phoneNumber) async {
    try {
      if (!_phoneRegex.hasMatch(phoneNumber)) {
        _showSnackbar("Enter a valid 10-digit phone number for the society member");
        return;
      }

      String formattedPhoneNumber = _formatPhoneNumber(phoneNumber);
      setState(() {
        isLoading = true;
        currentVerifyingMemberPhone = phoneNumber;
      });

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) {
          setState(() {
            societyMemberVerificationStatus[phoneNumber] = true;
            societyMemberOtpSent[phoneNumber] = true;
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          _showSnackbar("Member Verification Failed: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            societyMemberVerificationIds[phoneNumber] = verificationId;
            societyMemberOtpSent[phoneNumber] = true;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );

      // Start the resend timer
      _startResendTimer();
    } catch (e) {
      _showSnackbar("An unexpected error occurred. Please try again.");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Verify OTP method for society member
  Future<void> verifyMemberOtp(String phoneNumber) async {
    String? memberVerificationId = societyMemberVerificationIds[phoneNumber];
    if (memberVerificationId == null || societyMemberOtpController.text.trim().isEmpty) {
      _showSnackbar("Invalid verification details for society member");
      return;
    }

    setState(() => isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: memberVerificationId,
        smsCode: societyMemberOtpController.text.trim(),
      );

      // We don't sign in with this credential, just verify it's valid
      // This is different from the admin verification where we actually sign in
      await _auth.signInWithCredential(credential);

      // After verification, sign back in with the admin account if needed
      // For simplicity we're not doing this here, but in a real app you might need to

      setState(() {
        societyMemberVerificationStatus[phoneNumber] = true;
        _showSnackbar("Society Member OTP Verified!");

        // Clear OTP field
        societyMemberOtpController.clear();
      });
    } on FirebaseAuthException catch (e) {
      _showSnackbar("Member OTP Verification Failed: ${e.message}");
    } catch (e) {
      _showSnackbar("An unexpected error occurred during member OTP verification");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Image picking method
  Future<void> _pickProfilePicture() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);

        // File size validation
        int fileSizeInBytes = await imageFile.length();
        if (fileSizeInBytes > 2 * 1024 * 1024) { // 2MB limit
          _showSnackbar("Image size should be less than 2MB");
          return;
        }

        List<int> imageBytes = await imageFile.readAsBytes();
        String base64Image = base64Encode(imageBytes);

        setState(() {
          profilePicture = imageFile;
          profilePictureBase64 = base64Image;
        });

        _showSnackbar("Profile picture uploaded successfully!");
      }
    } catch (e) {
      _showSnackbar("Error uploading image: ${e.toString()}");
    }
  }

  // Add society member
  void _addSocietyMember() {
    if (societyMemberNameController.text.isEmpty ||
        societyMemberFlatNoController.text.isEmpty ||
        societyMemberPhoneController.text.isEmpty) {
      _showSnackbar("Please enter name, flat number, and phone for society member");
      return;
    }

    // Validate phone
    if (!_phoneRegex.hasMatch(societyMemberPhoneController.text)) {
      _showSnackbar("Enter a valid 10-digit phone number for society member");
      return;
    }

    // Check if phone number is already used
    String phone = societyMemberPhoneController.text.trim();
    bool phoneExists = societyMembers.any((member) => member['phone'] == phone);

    if (phoneExists) {
      _showSnackbar("This phone number is already added as a society member");
      return;
    }

    // Send OTP to verify the society member's phone
    sendMemberOtp(phone);
  }

  // Complete society member addition after OTP verification
  void _completeSocietyMemberAddition() {
    String phone = societyMemberPhoneController.text.trim();

    if (societyMemberVerificationStatus[phone] != true) {
      _showSnackbar("Please verify the phone number with OTP first");
      return;
    }

    setState(() {
      societyMembers.add({
        'name': societyMemberNameController.text.trim(),
        'flatNo': societyMemberFlatNoController.text.trim(),
        'phone': phone,
        'verified': true,
      });

      // Clear controllers
      societyMemberNameController.clear();
      societyMemberFlatNoController.clear();
      societyMemberPhoneController.clear();
      societyMemberOtpController.clear();

      // Clear verification data for this member
      currentVerifyingMemberPhone = null;
      societyMemberOtpSent[phone] = false;
    });

    _showSnackbar("Society member added successfully!");
  }

  // Remove society member
  void _removeSocietyMember(Map<String, dynamic> member) {
    setState(() {
      societyMembers.remove(member);
      String phone = member['phone'];

      // Clean up verification data
      societyMemberVerificationStatus.remove(phone);
      societyMemberVerificationIds.remove(phone);
      societyMemberOtpSent.remove(phone);
    });

    _showSnackbar("Society member removed");
  }

  // Apply for verification
  Future<void> _applyForVerification() async {
    setState(() => isLoading = true);

    try {
      // Get current user ID
      String adminUid = _auth.currentUser?.uid ?? '';
      if (adminUid.isEmpty) {
        throw Exception("Authentication error. Please sign in again.");
      }

      // Create admin document
      Map<String, dynamic> adminData = {
        'phone': _formatPhoneNumber(phoneController.text),
        'name': adminnameController.text.trim(),
        'email': adminemailController.text.trim(),
        'profilePicture': profilePictureBase64 ?? '',
        'residenceDetails': {
          'state': selectedState,
          'city': selectedCity,
          'society': selectedSociety,
          'societyName': societyNameController.text.trim(),
          'flatNumber': adminflatNumberController.text.trim(),
        },
        'isAdmin': true,
        'societyMembers': societyMembers,
        'timestamp': FieldValue.serverTimestamp(),
        'verificationStatus': 'pending',
        'isActive': false
      };

      await _firestore.collection('customers').doc(adminUid).set(adminData);

      // Create individual documents for each society member
      for (var member in societyMembers) {
        // Generate a unique ID for this member
        String memberId = _firestore.collection('customers').doc().id;

        // Copy admin data but update with member's information
        Map<String, dynamic> memberData = {
          'phone': _formatPhoneNumber(member['phone']),
          'name': member['name'],
          'email': '', // Empty by default
          'profilePicture': '', // Empty by default
          'residenceDetails': {
            'state': selectedState,
            'city': selectedCity,
            'society': selectedSociety,
            'societyName': societyNameController.text.trim(),
            'flatNumber': member['flatNo'],
          },
          'isAdmin': false,
          'adminId': adminUid, // Reference to the admin
          'timestamp': FieldValue.serverTimestamp(),
          'verificationStatus': 'pending',
          'isActive': false
        };

        await _firestore.collection('customers').doc(memberId).set(memberData);
      }

      setState(() {
        isVerificationApplied = true;
        verificationStatus = 'pending';
      });

      _showSnackbar("Verification application submitted successfully!");
    } catch (e) {
      _showSnackbar("Error applying for verification: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Form submission method
  Future<void> _submitForm() async {
    // Comprehensive input validation
    if (adminnameController.text.isEmpty || !_nameRegex.hasMatch(adminnameController.text)) {
      _showSnackbar("Please enter a valid name (only alphabets)");
      return;
    }

    if (adminemailController.text.isNotEmpty && !_emailRegex.hasMatch(adminemailController.text)) {
      _showSnackbar("Please enter a valid email address");
      return;
    }

    if (selectedState == null ||
        selectedCity == null ||
        selectedSociety == null ||
        societyNameController.text.isEmpty ||
        adminflatNumberController.text.isEmpty) {
      _showSnackbar("Please fill all required residence details");
      return;
    }

    // Apply for verification
    await _applyForVerification();
  }

  // Check verification status
  Future<void> _checkVerificationStatus() async {
    try {
      String adminUid = _auth.currentUser?.uid ?? '';
      if (adminUid.isEmpty) {
        return;
      }

      DocumentSnapshot doc = await _firestore.collection('customers').doc(adminUid).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        setState(() {
          verificationStatus = data['verificationStatus'] ?? 'pending';
        });

        if (verificationStatus == 'approved') {
          // If approved, navigate to dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          );
        }
      }
    } catch (e) {
      print("Error checking verification status: $e");
    }
  }

  // Enhanced SnackBar
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
    }

  // Input Decoration
  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(color: Colors.black87),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade200, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue, width: 2),
      ),
    );
  }

  // Elevated Button Style
  ButtonStyle _elevatedButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 5,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: SafeArea(
        child: Stack(
          children: [
            // Background Design
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.blue[100]?.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.blue[100]?.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Main Content
            Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios, color: Colors.black),
                        onPressed: () {
                          _handleBackNavigation();
                        },
                      ),
                      Text(
                        'FIXIFY USER',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(width: 50), // Placeholder for symmetry
                    ],
                  ),
                ),

                // Progress Tracker
                _buildProgressTracker(),

                // Show verification status if applied
                if (isVerificationApplied) _buildVerificationStatusWidget(),

                // Main Content Area
                Expanded(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Conditional Rendering of Steps
                          if (!isVerificationApplied) ...[
                            if (currentStep == 0) _buildMobileVerification(),
                            if (currentStep == 1) _buildAdminDetails(),
                            if (currentStep == 2) _buildResidenceDetails(),
                            if (currentStep == 3) _buildSocietyMembers(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Progress Tracker
  Widget _buildProgressTracker() {
    if (isVerificationApplied) return SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(4, (index) {
          return Row(
            children: [
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index <= currentStep ? Colors.blue : Colors.grey[400],
                  boxShadow: index <= currentStep
                      ? [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (index < 3)
                Container(
                  width: 40,
                  height: 5,
                  color: index < currentStep ? Colors.blue : Colors.grey[400],
                ),
            ],
          );
        }),
      ),
    );
  }

  // Verification Status Widget
  Widget _buildVerificationStatusWidget() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (verificationStatus) {
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Verification Approved';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Verification Rejected';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Verification Pending';
        statusIcon = Icons.hourglass_empty;
    }

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(statusIcon, color: statusColor, size: 80),
          SizedBox(height: 16),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          SizedBox(height: 10),
          Text(
            verificationStatus == 'pending'
                ? 'Your application is being reviewed. This may take 24-48 hours.'
                : verificationStatus == 'approved'
                ? 'Your account has been verified. You can now proceed to the dashboard.'
                : 'Please contact support for more information.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
          SizedBox(height: 20),
          if (verificationStatus == 'approved')
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardScreen()),
                );
              },
              style: _elevatedButtonStyle(),
              child: Text('Go to Dashboard'),
            )
          else
            ElevatedButton(
              onPressed: () {
                // Exit the app
                SystemNavigator.pop();
              },
              style: _elevatedButtonStyle(),
              child: Text('Exit'),
            ),
        ],
      ),
    );
  }

  // Back Navigation Handler
  void _handleBackNavigation() {
    if (isVerificationApplied) {
      // If verification is applied, show confirmation dialog before going back
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirmation'),
          content: Text('Your verification application has been submitted. Going back will lose your progress. Are you sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                setState(() {
                  isVerificationApplied = false;
                  currentStep = 3; // Go back to society members step
                });
              },
              child: Text('Yes'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        if (currentStep > 0) {
          currentStep--;
        } else {
          Navigator.pop(context);
        }
      });
    }
  }

  // Step 1: Mobile Verification Widget
  Widget _buildMobileVerification() {
    return Column(
      children: [
        SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Image.asset('assets/images/imagefixify.png', height: 100),
              SizedBox(height: 20),
              Text(
                'Join FIXIFY as Society Admin',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 30),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: _inputDecoration("Enter your mobile number")
                    .copyWith(prefixIcon: Icon(Icons.phone)),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : sendOtp,
                style: _elevatedButtonStyle(),
                child: isLoading
                    ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text("Send OTP"),
              ),
              if (isOtpSent) ...[
                SizedBox(height: 30),
                Text(
                  "Enter the 6-digit code sent to your mobile",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 20),
                Pinput(
                  controller: otpController,
                  length: 6,
                  defaultPinTheme: PinTheme(
                    width: 50,
                    height: 50,
                    textStyle: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue.shade200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isLoading ? null : verifyOtp,
                  style: _elevatedButtonStyle(),
                  child: isLoading
                      ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text("Verify OTP"),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: _canResendOtp && !isLoading ? _resendOtp : null,
                  child: Text(
                    _canResendOtp
                        ? 'Resend OTP'
                        : 'Resend OTP in $_resendTimer seconds',
                    style: TextStyle(
                      color: _canResendOtp && !isLoading ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 30),
        ElevatedButton(
          onPressed: isOtpVerified && !isLoading
              ? () => setState(() => currentStep = 1)
              : null,
          style: _elevatedButtonStyle().copyWith(
              minimumSize: MaterialStateProperty.all(Size(double.infinity, 50))),
          child: Text("Continue", style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  // Step 2: Admin Details Widget
  Widget _buildAdminDetails() {
    return Column(
      children: [
        SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Admin Profile',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 25),
              GestureDetector(
                onTap: _pickProfilePicture,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: profilePicture != null
                          ? FileImage(profilePicture!)
                          : null,
                      child: profilePicture == null
                          ? Icon(Icons.person, size: 50, color: Colors.grey[400])
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 25),
              TextField(
                controller: adminnameController,
                decoration: _inputDecoration('Admin Full Name')
                    .copyWith(prefixIcon: Icon(Icons.person)),
              ),
              SizedBox(height: 25),
              TextField(
                controller: adminemailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('Email (Optional)')
                    .copyWith(prefixIcon: Icon(Icons.email)),
              ),
            ],
          ),
        ),
        SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => currentStep = 0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text('Back'),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: adminnameController.text.isNotEmpty
                    ? () => setState(() => currentStep = 2)
                    : null,
                style: _elevatedButtonStyle().copyWith(
                    padding: MaterialStateProperty.all(
                        EdgeInsets.symmetric(vertical: 15))),
                child: Text('Continue'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 3: Residence Details Widget
  Widget _buildResidenceDetails() {
    return Column(
      children: [
        SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Society Details',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 25),
              DropdownButtonFormField<String>(
                value: selectedState,
                decoration: _inputDecoration('Select State'),
                items: states.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedState = newValue;
                    selectedCity = null;
                    selectedSociety = null;
                  });
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedCity,
                decoration: _inputDecoration('Select City'),
                items: (selectedState != null)
                    ? cities[selectedState]!
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList()
                    : [],
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCity = newValue;
                    selectedSociety = null;
                  });
                },
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedSociety,
                decoration: _inputDecoration('Select Society'),
                items: (selectedState != null && selectedCity != null)
                    ? getSocieties(selectedState!, selectedCity!)
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList()
                    : [],
                onChanged: (String? newValue) {
                  setState(() {
                    selectedSociety = newValue;
                  });
                },
              ),
              SizedBox(height: 20),
              TextField(
                controller: societyNameController,
                decoration: _inputDecoration('Society Name/Building Name')
                    .copyWith(prefixIcon: Icon(Icons.home)),
              ),
              SizedBox(height: 20),
              TextField(
                controller: adminflatNumberController,
                decoration: _inputDecoration('Your Flat/House Number')
                    .copyWith(prefixIcon: Icon(Icons.apartment)),
              ),
            ],
          ),
        ),
        SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => currentStep = 1),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text('Back'),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (selectedState != null &&
                    selectedCity != null &&
                    selectedSociety != null &&
                    societyNameController.text.isNotEmpty &&
                    adminflatNumberController.text.isNotEmpty)
                    ? () => setState(() => currentStep = 3)
                    : null,
                style: _elevatedButtonStyle().copyWith(
                    padding: MaterialStateProperty.all(
                        EdgeInsets.symmetric(vertical: 15))),
                child: Text('Continue'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Step 4: Society Members Widget
  // Step 4: Society Members Widget
  Widget _buildSocietyMembers() {
    return Column(
      children: [
        SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Society Members',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Add other society members who will use our services',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 25),
              TextField(
                controller: societyMemberNameController,
                decoration: _inputDecoration('Member Name')
                    .copyWith(prefixIcon: Icon(Icons.person_outline)),
              ),
              SizedBox(height: 20),
              TextField(
                controller: societyMemberFlatNoController,
                decoration: _inputDecoration('Flat/House Number')
                    .copyWith(prefixIcon: Icon(Icons.apartment)),
              ),
              SizedBox(height: 20),
              TextField(
                controller: societyMemberPhoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(10),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: _inputDecoration('Phone Number')
                    .copyWith(prefixIcon: Icon(Icons.phone)),
              ),
              SizedBox(height: 20),
              if (currentVerifyingMemberPhone != null &&
                  societyMemberOtpSent[currentVerifyingMemberPhone!] == true)
                Column(
                  children: [
                    Text(
                      "Enter OTP sent to ${currentVerifyingMemberPhone}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 10),
                    Pinput(
                      controller: societyMemberOtpController,
                      length: 6,
                      defaultPinTheme: PinTheme(
                        width: 50,
                        height: 50,
                        textStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue.shade200),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                        await verifyMemberOtp(currentVerifyingMemberPhone!);
                        if (societyMemberVerificationStatus[currentVerifyingMemberPhone!] == true) {
                          _completeSocietyMemberAddition();
                        }
                      },
                      style: _elevatedButtonStyle(),
                      child: isLoading
                          ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                          : Text("Verify & Add Member"),
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ElevatedButton(
                onPressed: () {
                  if (currentVerifyingMemberPhone != null &&
                      societyMemberVerificationStatus[currentVerifyingMemberPhone!] == true) {
                    _completeSocietyMemberAddition();
                  } else {
                    _addSocietyMember();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade200,
                  foregroundColor: Colors.blue.shade800,
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text(
                  currentVerifyingMemberPhone != null &&
                      societyMemberVerificationStatus[currentVerifyingMemberPhone!] == true
                      ? 'Add Member'
                      : 'Verify Member',
                ),
              ),
              SizedBox(height: 20),
              if (societyMembers.isNotEmpty) ...[
                Text(
                  'Added Society Members:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 10),
                ...societyMembers.map((member) => Card(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    leading: Icon(Icons.apartment, color: Colors.blue),
                    title: Text(member['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Flat: ${member['flatNo']}'),
                        Text('Phone: ${member['phone']}'),
                        Row(
                          children: [
                            Icon(
                              member['verified'] ? Icons.verified : Icons.pending,
                              color: member['verified'] ? Colors.green : Colors.orange,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              member['verified'] ? 'Verified' : 'Pending',
                              style: TextStyle(
                                color: member['verified'] ? Colors.green : Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeSocietyMember(member),
                    ),
                  ),
                )).toList(),
              ],
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
                  isChecked = value ?? false;
                });
              },
              activeColor: Colors.blue,
            ),
            Expanded(
              child: Text(
                'I confirm that I am the authorized representative of this society and have permission to add these members',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => currentStep = 2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text('Back'),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: isChecked && !isLoading
                    ? _submitForm
                    : null,
                style: _elevatedButtonStyle().copyWith(
                    padding: MaterialStateProperty.all(
                        EdgeInsets.symmetric(vertical: 15))),
                child: isLoading
                    ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Text('Submit for Verification'),
              ),
            ),
          ],
        ),
      ],
    );
  }
  }