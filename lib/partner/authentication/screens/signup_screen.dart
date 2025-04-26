import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pinput/pinput.dart';
import 'package:fixifypartner/partner/dash/screens/dashboard.dart';
import 'package:fixifypartner/partner/authentication/screens/verificationapplied.dart';
import 'package:geolocator/geolocator.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int currentStep = -1;
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();


  String? selectedGender = 'Male';
  String? selectedState;
  String? selectedCity;
  String? verificationId;
  String? selectedPartnerType;
  bool isOtpSent = false;
  bool isFileUploaded = false;
  bool isLoading = false;
  File? addressProof;
  bool isOtpVerified = false;
  String? addressProofBase64;
  bool isChecked = false;

  // OTP Timer Variables
  int _resendTimer = 60;
  Timer? _timer;
  bool _canResendOtp = false;



  // Enhanced Location Data
  Map<String, Map<String, dynamic>> enhancedLocations = {
    'Maharashtra': {
      'cities': ['Mumbai', 'Pune', 'Nagpur'],
      'hotspots': {
        'Mumbai': ['Bandra', 'Juhu', 'Andheri', 'Colaba'],
        'Pune': ['Koregaon Park', 'Baner', 'Wakad', 'Hinjewadi'],
        'Nagpur': ['Sitabuldi', 'Dharampeth', 'Sadar']
      }
    },
    'Gujarat': {
      'cities': ['Ahmedabad', 'Surat'],
      'hotspots': {
        'Ahmedabad': ['Satellite', 'Vastrapur', 'Bodakdev', 'CG Road'],
        'Surat': ['Adajan', 'VIP Road', 'Vesu', 'Majura Gate']
      }
    },
    'Delhi': {
      'cities': ['New Delhi'],
      'hotspots': {
        'New Delhi': ['Connaught Place', 'Hauz Khas', 'Nehru Place', 'Saket']
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

// Get hotspots for a specific city
  List<String> getHotspots(String state, String city) {
    return (enhancedLocations[state]!['hotspots'][city] as List<dynamic>).cast<String>();
  }

  // Radius options
  List<String> radiusOptions = ['Up to 0.5 km', 'Up to 1 km'];
  String? selectedRadius;
  String? selectedHotspot;

  // Validation Regex
  final RegExp _nameRegex = RegExp(r'^[a-zA-Z ]+$');
  final RegExp _ageRegex = RegExp(r'^[0-9]+$');

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

  // Method to resend OTP
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

  @override
  void dispose() {
    _timer?.cancel();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
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

  // Send OTP method
  Future<void> sendOtp() async {
    try {
      String phoneNumber = _formatPhoneNumber(phoneController.text);

      if (phoneController.text.length != 10) {
        _showSnackbar("Enter a valid 10-digit phone number");
        return;
      }

      try {
        var userDoc = await _firestore.collection('users').doc(phoneNumber).get();
        if (userDoc.exists) {
          _showSnackbar("Phone number already registered. Please login.");
          return;
        }
      } catch (firestoreError) {
        _showSnackbar("Error checking phone number. Please try again.");
        return;
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
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
    }
  }

  // Verify OTP method
  Future<void> verifyOtp() async {
    if (verificationId == null || otpController.text.trim().isEmpty) {
      _showSnackbar("Invalid verification details");
      return;
    }

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
    }
  }

  // Image picking method
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

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => isLoading = true);

      // Check and request permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackbar('Please enable location services');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackbar('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showSnackbar('Location permissions are permanently denied');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Update controllers
      setState(() {
        latitudeController.text = position.latitude.toStringAsFixed(6);
        longitudeController.text = position.longitude.toStringAsFixed(6);
      });

    } catch (e) {
      _showSnackbar('Error getting location: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Form submission method
  Future<void> _submitForm() async {
    // Comprehensive input validation
    if (nameController.text.isEmpty || !_nameRegex.hasMatch(nameController.text)) {
      _showSnackbar("Please enter a valid name (only alphabets)");
      return;
    }

    if (ageController.text.isEmpty ||
        !_ageRegex.hasMatch(ageController.text) ||
        int.parse(ageController.text) < 18 ||
        int.parse(ageController.text) > 80) {
      _showSnackbar("Please enter a valid age between 18 and 80");
      return;
    }

    if (selectedGender == null ||
        selectedState == null ||
        selectedCity == null ||
        selectedHotspot == null ||
        selectedRadius == null) {
      _showSnackbar("Please fill all required details");
      return;
    }

    setState(() => isLoading = true);

    try {
      String phoneNumber = _formatPhoneNumber(phoneController.text);

      await _firestore.collection('users').doc(phoneNumber).set({
        'phone': phoneNumber,
        'name': nameController.text.trim(),
        'age': ageController.text.trim(),
        'gender': selectedGender,
        'partnerType': selectedPartnerType,
        'locationDetails': {
          'state': selectedState,
          'city': selectedCity,
          'hotspot': selectedHotspot,
          'serviceRadius': selectedRadius,
          'latitude': double.tryParse(latitudeController.text) ?? 0.0,
          'longitude': double.tryParse(longitudeController.text) ?? 0.0,
          'geoPoint': GeoPoint(
              double.tryParse(latitudeController.text) ?? 0.0,
              double.tryParse(longitudeController.text) ?? 0.0,
            ),
        },
        'addressProof': addressProofBase64 ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'verificationStatus': isFileUploaded ? 'pending' : 'unverified'
      });

      _showSnackbar("Signup Complete!");
    } catch (e) {
      _showSnackbar("Error saving data: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
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
      ),
    );
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
        borderSide: BorderSide(color: Colors.yellow.shade200, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.black, width: 2),
      ),
    );
  }

  // Elevated Button Style
  ButtonStyle _elevatedButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
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
      backgroundColor: Colors.yellow[100],
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
                  color: Colors.yellow[200]?.withOpacity(0.5),
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
                  color: Colors.yellow[200]?.withOpacity(0.5),
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
                        'FIXIFY PARTNER',
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
                if (currentStep >= 0) _buildProgressTracker(),

                // Main Content Area
                Expanded(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          // Conditional Rendering of Steps
                          if (currentStep == -1) _buildPartnerSelection(),
                          if (currentStep == 0) _buildContactVerification(),
                          if (currentStep == 1) _buildPersonalDetails(),
                          if (currentStep == 2) _buildLocationSelection(),
                          if (currentStep == 3) _buildKYCUpload(),
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
                  color: index <= currentStep ? Colors.black : Colors.grey[400],
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
                  color: index < currentStep ? Colors.black : Colors.grey[400],
                ),
            ],
          );
        }),
      ),
    );
  }

  // Back Navigation Handler
  void _handleBackNavigation() {
    setState(() {
      switch (currentStep) {
        case -1:
          Navigator.pop(context);
          break;
        case 0:
          currentStep = -1;
          break;
        case 1:
          currentStep = 0;
          break;
        case 2:
          currentStep = 1;
          break;
        case 3:
          currentStep = 2;
          break;
      }
    });
  }


  // Partner Selection Widget
  Widget _buildPartnerSelection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 80),
        Image.asset('assets/images/imagefixify.png', height: 150),
        Text('FIXIFY',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
        SizedBox(height: 50),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButton<String>(
            value: selectedPartnerType,
            hint: Text('Select Partner Type', style: TextStyle(fontSize: 18)),
            isExpanded: true,
            items: ['Plumber', 'Electrician', 'Locksmith'].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: TextStyle(fontSize: 18)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedPartnerType = value!;
              });
            },
          ),
        ),
        SizedBox(height: 50),
        ElevatedButton(
          onPressed: selectedPartnerType == null
              ? null
              : () {
            setState(() {
              currentStep = 0;
            });
          },
          style: _elevatedButtonStyle(),
          child: Text('Continue', style: TextStyle(fontSize: 20)),
        ),
      ],
    );
  }

  // Contact Verification Widget
  Widget _buildContactVerification() {
    return Column(
        children: [
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                SizedBox(height: 30),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration("Enter your phone number"),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: sendOtp,
                  style: _elevatedButtonStyle(),
                  child: Text("Send OTP"),
                ),
                SizedBox(height: 10),
                TextButton(
                  onPressed: _canResendOtp ? _resendOtp : null,
                  child: Text(
                    _canResendOtp
                        ? 'Resend OTP'
                        : 'Resend OTP in $_resendTimer seconds',
                    style: TextStyle(
                      color: _canResendOtp ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),
                SizedBox(height: 50),
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
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: verifyOtp,
                  style: _elevatedButtonStyle(),
                  child: Text("Verify OTP"),
                ),
                SizedBox(height: 60),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: isOtpVerified
                ? () => setState(() => currentStep = 1)
                : null,
            style: _elevatedButtonStyle(),
            child: Text("Continue"),
          ),]);
  }

  // Personal Details Widget
  Widget _buildPersonalDetails() {
    return Column(
      children: [
        SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              SizedBox(height: 25),
              TextField(
                controller: nameController,
                decoration: _inputDecoration('Full Name'),
              ),
              SizedBox(height: 25),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Age'),
              ),
              SizedBox(height: 25),
              DropdownButton<String>(
                value: selectedGender,
                isExpanded: true,
                items: ['Male', 'Female', 'Other']
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e, style: TextStyle(fontSize: 18)),
                ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => selectedGender = val);
                  }
                },
              ),
              SizedBox(height: 25),
              TextField(
                controller: addressController,
                decoration: _inputDecoration('Residential Address'),
              ),
            ],
          ),
        ),
        SizedBox(height: 50),
        ElevatedButton(
          onPressed: () => setState(() => currentStep = 2),
          style: _elevatedButtonStyle(),
          child: Text('Continue', style: TextStyle(fontSize: 20)),
        ),
      ],
    );
  }

  // Location Selection Widget
  Widget _buildLocationSelection() {
    return Column(
      children: [
        SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Text(
                'REGISTER YOUR AREA OF WORK',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                'PARTNERS GET BOOKING FROM SOCITIES WITHIN THE RADIUS OF LANDMARK)',
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 30),

              DropdownButton<String>(
                value: selectedState,
                isExpanded: true,
                hint: Text('Select State', style: TextStyle(fontSize: 18)),
                items: states.map<DropdownMenuItem<String>>((String e) {
                  return DropdownMenuItem<String>(
                    value: e,
                    child: Text(e, style: TextStyle(fontSize: 18)),
                  );
                }).toList(),
                onChanged: (String? val) {
                  setState(() {
                    selectedState = val;
                    selectedCity = null;
                    selectedHotspot = null;
                  });
                },
              ),
              SizedBox(height: 20),
              DropdownButton<String>(
                value: selectedCity,
                isExpanded: true,
                hint: Text('Select City', style: TextStyle(fontSize: 18)),
                items: (selectedState != null ? cities[selectedState]! : <String>[])
                    .map<DropdownMenuItem<String>>((String e) {
                  return DropdownMenuItem<String>(
                    value: e,
                    child: Text(e, style: TextStyle(fontSize: 18)),
                  );
                }).toList(),
                onChanged: (String? val) {
                  setState(() {
                    selectedCity = val;
                    selectedHotspot = null;
                  });
                },
              ),
              SizedBox(height: 20),
              DropdownButton<String>(
                value: selectedHotspot,
                isExpanded: true,
                hint: Text('Select Hotspot', style: TextStyle(fontSize: 18)),
                items: (selectedState != null && selectedCity != null)
                    ? getHotspots(selectedState!, selectedCity!)
                    .map<DropdownMenuItem<String>>((String e) {
                  return DropdownMenuItem<String>(
                    value: e,
                    child: Text(e, style: TextStyle(fontSize: 18)),
                  );
                }).toList()
                    : [],
                onChanged: (String? val) {
                  setState(() {
                    selectedHotspot = val;
                  });
                },
              ),
              SizedBox(height: 20),
              DropdownButton<String>(
                value: selectedRadius,
                isExpanded: true,
                hint: Text('Select Service Radius', style: TextStyle(fontSize: 18)),
                items: radiusOptions.map<DropdownMenuItem<String>>((String e) {
                  return DropdownMenuItem<String>(
                    value: e,
                    child: Text(e, style: TextStyle(fontSize: 18)),
                  );
                }).toList(),
                onChanged: (String? val) {
                  setState(() {
                    selectedRadius = val;
                  });
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: TextField(
                readOnly: true, // Make field non-editable
                controller: latitudeController,
                decoration: _inputDecoration('Latitude')
                    .copyWith(prefixIcon: Icon(Icons.my_location)),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextField(
                readOnly: true, // Make field non-editable
                controller: longitudeController,
                decoration: _inputDecoration('Longitude')
                    .copyWith(prefixIcon: Icon(Icons.my_location)),
              ),
            ),
          ],
        ),
        SizedBox(height: 15),
        ElevatedButton.icon(
          onPressed: () {
            _getCurrentLocation();
          },
          icon: Icon(Icons.location_searching),
          label: Text('Get Current Location'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
          ),
        ),
        SizedBox(height: 30),
        ElevatedButton(
          onPressed: (selectedState != null &&
              selectedCity != null &&
              selectedHotspot != null &&
              selectedRadius != null &&
              latitudeController.text.isNotEmpty &&
              longitudeController.text.isNotEmpty )
              ? () => setState(() => currentStep = 3)
              : null,
          style: _elevatedButtonStyle(),
          child: Text('Continue', style: TextStyle(fontSize: 20)),
        ),
      ],
    );
  }

  Widget _buildKYCUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UPLOAD ADDRESS PROOF',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Please upload any of your address proof below for completing your Verification',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 30),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                'Aadhar Card / Voter ID / Electricity Bill',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: Icon(Icons.upload),
                label: Text('Upload +'),
                style: _elevatedButtonStyle(),
              ),
              if (isFileUploaded)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Document uploaded successfully!',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 30),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: isChecked,
              onChanged: (bool? value) {
                setState(() {
                  isChecked = value ?? false;
                });
              },
            ),
            Expanded(
              child: Text(
                'I hereby agree that the above document belongs to me and voluntarily give my consent to Fixify to utilize it as my address proof for KYC purpose only',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (isFileUploaded && isChecked && !isLoading)
                ? () async {
              setState(() => isLoading = true);
              await _submitForm();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => VerificationAppliedScreen()),
              );
            }
                : null,
            style: _elevatedButtonStyle(),
            child: isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text('Submit for Verification'),
          ),
        ),
        SizedBox(height: 40),
        Center(
          child: TextButton(
            onPressed: () {
              _submitForm();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()),
              );
            },
            child: Text(
              'Continue without verification',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'NOTE: Verified partners get listed as VERIFIED users.\nTrusted verified partners get more service requests.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}