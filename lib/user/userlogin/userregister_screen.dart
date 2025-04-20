import 'dart:async';
import 'package:fixifypartner/partner/authentication/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter/services.dart';
import 'package:fixifypartner/user/userlogin/onboardingscreen.dart';
import 'package:fixifypartner/user/userlogin/usersignup_screen.dart';
import 'package:share_plus/share_plus.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({Key? key}) : super(key: key);

  @override
  _CustomerLoginScreenState createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool isLoading = false;
  bool isOtpSent = false;
  String? verificationId;
  String? errorMessage;
  String verificationStatus = 'pending';
  bool isVerificationApplied = false;
  bool isLocationSelected = false;

  // Location selectors
  String? selectedState;
  String? selectedCity;
  String? selectedSociety;

  // Dynamic location data
  Map<String, Map<String, dynamic>> dynamicLocations = {};
  bool isLoadingLocations = true;

  // Fallback location data
  final Map<String, Map<String, dynamic>> enhancedLocations = {
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

  // OTP Timer Variables
  int _resendTimer = 60;
  Timer? _timer;
  bool _canResendOtp = false;

  @override
  void initState() {
    super.initState();
    fetchSocieties();
  }

  @override
  void dispose() {
    _timer?.cancel();
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  // Method to fetch societies from Firestore
  Future<void> fetchSocieties() async {
    setState(() {
      isLoadingLocations = true;
    });

    try {
      // Create a map to organize locations hierarchically
      Map<String, Map<String, dynamic>> locations = {};

      // Get all customers
      QuerySnapshot customersSnapshot = await _firestore.collection('customers').get();

      for (var doc in customersSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Check if residenceDetails exists and has state, city, and society
        if (data.containsKey('residenceDetails')) {
          Map<String, dynamic> residence = data['residenceDetails'] as Map<String, dynamic>;

          String state = residence['state'] ?? 'Unknown';
          String city = residence['city'] ?? 'Unknown';
          String society = residence['society'] ?? 'Unknown';

          // Skip if any value is unknown
          if (state == 'Unknown' || city == 'Unknown' || society == 'Unknown') continue;

          // Initialize state if it doesn't exist
          if (!locations.containsKey(state)) {
            locations[state] = {
              'cities': <String>{},
              'societies': <String, Set<String>>{}
            };
          }

          // Add city to set of cities for this state
          (locations[state]!['cities'] as Set<String>).add(city);

          // Initialize societies map for this city if needed
          if (!(locations[state]!['societies'] as Map<String, Set<String>>).containsKey(city)) {
            (locations[state]!['societies'] as Map<String, Set<String>>)[city] = <String>{};
          }

          // Add society to set of societies for this city
          (locations[state]!['societies'] as Map<String, Set<String>>)[city]!.add(society);
        }
      }

      // Convert sets to lists for the UI
      Map<String, Map<String, dynamic>> formattedLocations = {};

      locations.forEach((state, stateData) {
        formattedLocations[state] = {
          'cities': (stateData['cities'] as Set<String>).toList()..sort(),
          'societies': <String, List<String>>{}
        };

        (stateData['societies'] as Map<String, Set<String>>).forEach((city, societies) {
          (formattedLocations[state]!['societies'] as Map<String, List<String>>)[city] = societies.toList()..sort();
        });
      });

      setState(() {
        dynamicLocations = formattedLocations;
        isLoadingLocations = false;
      });

      // If no locations were found, use the fallback locations
      if (dynamicLocations.isEmpty) {
        setState(() {
          dynamicLocations = enhancedLocations;
        });
      }

      print("DEBUG: Fetched ${dynamicLocations.length} states from database");
    } catch (e) {
      print("DEBUG: Error fetching societies: $e");
      setState(() {
        // Use fallback if there's an error
        dynamicLocations = enhancedLocations;
        isLoadingLocations = false;
      });
    }
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

  Future<void> _resendOtp() async {
    if (phoneController.text.length != 10) {
      setState(() => errorMessage = "Enter a valid 10-digit phone number");
      return;
    }

    if (_canResendOtp) {
      await sendOtp();
      _startResendTimer();
    }
  }

  final RegExp _phoneRegex = RegExp(r'^[0-9]{10}$');

  String _formatPhoneNumber(String rawNumber) {
    try {
      String digits = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length == 10) return '+91$digits';
      if (digits.startsWith('91') && digits.length == 12) return '+$digits';
      return '+91$digits'; // Default to adding +91 if not sure
    } catch (e) {
      return rawNumber; // Return original if formatting fails
    }
  }

  Future<bool> _checkUserExists(String phoneNumber) async {
    try {
      final formattedPhone = _formatPhoneNumber(phoneNumber);
      print("DEBUG: Searching for phone: $formattedPhone");

      // Check all possible phone number formats
      final queries = [
        _firestore.collection('customers').where('phone', isEqualTo: formattedPhone),
        _firestore.collection('customers').where('phone', isEqualTo: formattedPhone.replaceFirst('+91', '')),
        _firestore.collection('customers').where('phone', isEqualTo: '91${phoneController.text}'),
        _firestore.collection('customers').where('phone', isEqualTo: phoneController.text),
      ];

      for (var query in queries) {
        final querySnapshot = await query.get();
        if (querySnapshot.docs.isNotEmpty) {
          print("DEBUG: Found user with phone format: ${querySnapshot.docs.first['phone']}");

          if (selectedSociety != null) {
            // Check the nested society field
            final societyMatch = querySnapshot.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              return data != null &&
                  data.containsKey('residenceDetails') &&
                  (data['residenceDetails'] as Map<String, dynamic>).containsKey('society') &&
                  data['residenceDetails']['society'] == selectedSociety;
            }).toList();

            if (societyMatch.isEmpty) {
              setState(() {
                errorMessage = "This number is not registered in $selectedSociety society";
              });
              return false;
            }
          }

          // Also update verificationStatus access if it's nested
          setState(() {
            verificationStatus = querySnapshot.docs.first['verificationStatus'] ?? 'pending';
          });
          return true;
        }
      }

      setState(() {
        errorMessage = "This number is not registered. Please sign up first.";
      });
      return false;

    } catch (e) {
      print("DEBUG: Error in _checkUserExists: $e");
      setState(() {
        errorMessage = "Error checking user. Please try again.";
      });
      return false;
    }
  }

  Future<void> sendOtp() async {
    try {
      if (!_phoneRegex.hasMatch(phoneController.text)) {
        setState(() => errorMessage = "Enter a valid 10-digit phone number");
        return;
      }

      print("DEBUG: Starting OTP send process for ${phoneController.text}");
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      bool userExists = await _checkUserExists(phoneController.text);
      print("DEBUG: User exists check result: $userExists");

      if (!userExists) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      String phoneNumber = _formatPhoneNumber(phoneController.text);

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          await _checkVerificationStatus();
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => errorMessage = "Verification Failed: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            this.verificationId = verificationId;
            isOtpSent = true;
          });
          _startResendTimer();
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() => errorMessage = "An unexpected error occurred");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> verifyOtp() async {
    if (verificationId == null || otpController.text.trim().isEmpty) {
      setState(() => errorMessage = "Invalid verification details");
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otpController.text.trim(),
      );

      // Sign in with credential
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Authentication failed',
        );
      }

      // Check verification status after sign-in
      await _checkVerificationStatus();

    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = "Verification failed: ${e.message}";
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "An unexpected error occurred";
        isLoading = false;
      });
    }
  }

  // Fix in _checkVerificationStatus() method
  Future<void> _checkVerificationStatus() async {
    try {
      setState(() => isLoading = true);

      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final doc = await _firestore.collection('customers').doc(user.uid).get();
      if (!doc.exists) {
        if (mounted) setState(() => isLoading = false);
        return;
      }

      final status = doc['verificationStatus'] as String? ?? 'pending';
      print('VERIFICATION STATUS: $status');

      // Only proceed if the widget is still mounted
      if (!mounted) return;

      // Update state first
      setState(() {
        verificationStatus = status;
        isVerificationApplied = true;
        isLoading = false;
      });

      // Then navigate if approved
      if (status == 'approved') {
        // Add a small delay to ensure state updates before navigation
        await Future.delayed(Duration(milliseconds: 100));
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => OnboardingScreen()),
                (route) => false,
          );
        }
      }
    } catch (e) {
      print('Error checking status: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.black87),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade200, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      errorText: errorMessage,
    );
  }

  ButtonStyle _elevatedButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 5,
    );
  }

  InputDecoration _dropdownDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.black87),
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blue.shade200, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildVerificationStatusWidget() {

    if (verificationStatus == 'approved') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Verification approved! Redirecting...'),
          ],
        ),
      );
    }

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (verificationStatus) {
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
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(statusIcon, color: statusColor, size: 80),
          const SizedBox(height: 16),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            verificationStatus == 'pending'
                ? 'Your application is under review. Please check back later.'
                : verificationStatus == 'approved'
                ? 'Your account has been verified. You can now proceed to login.'
                : 'Please contact support for more information.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          if (verificationStatus == 'rejected')
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => CustomerSignUpScreen()),
                );
              },
              style: _elevatedButtonStyle(),
              child: const Text('Contact Support'),
            )
          else
            ElevatedButton(
              onPressed: _checkVerificationStatus,
              style: _elevatedButtonStyle(),
              child: const Text('Check Status Again'),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationSelectors() {
    // Use dynamicLocations instead of enhancedLocations
    final locationsData = isLoadingLocations ? enhancedLocations : dynamicLocations;

    return Column(
      children: [
        // Show loading indicator while fetching locations
        if (isLoadingLocations)
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text(
                  "Loading societies...",
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // State Selector
        DropdownButtonFormField<String>(
          value: selectedState,
          decoration: _dropdownDecoration('Select State'),
          items: locationsData.keys.map((String state) {
            return DropdownMenuItem<String>(
              value: state,
              child: Text(state),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedState = newValue;
              selectedCity = null;
              selectedSociety = null;
              isLocationSelected = false;
            });
          },
          isExpanded: true,
        ),
        const SizedBox(height: 16),

        // City Selector
        DropdownButtonFormField<String>(
          value: selectedCity,
          decoration: _dropdownDecoration('Select City'),
          items: (selectedState != null && locationsData.containsKey(selectedState))
              ? (locationsData[selectedState]!['cities'] as List<String>).map((String city) {
            return DropdownMenuItem<String>(
              value: city,
              child: Text(city),
            );
          }).toList()
              : [],
          onChanged: selectedState == null
              ? null
              : (String? newValue) {
            setState(() {
              selectedCity = newValue;
              selectedSociety = null;
              isLocationSelected = false;
            });
          },
          isExpanded: true,
        ),
        const SizedBox(height: 16),

        // Society Selector
        DropdownButtonFormField<String>(
          value: selectedSociety,
          decoration: _dropdownDecoration('Select Your Society'),
          items: (selectedState != null && selectedCity != null &&
              locationsData.containsKey(selectedState) &&
              (locationsData[selectedState]!['societies'] as Map<String, dynamic>).containsKey(selectedCity))
              ? (locationsData[selectedState]!['societies'][selectedCity] as List<String>)
              .map((String society) {
            return DropdownMenuItem<String>(
              value: society,
              child: Text(society),
            );
          }).toList()
              : [],
          onChanged: (selectedState == null || selectedCity == null)
              ? null
              : (String? newValue) {
            setState(() {
              selectedSociety = newValue;
              isLocationSelected = selectedSociety != null;
            });
          },
          isExpanded: true,
        ),
        const SizedBox(height: 25),

        // Proceed to Login Button
        ElevatedButton(
          onPressed: isLocationSelected
              ? () {
            setState(() {
              isLocationSelected = true;
            });
          }
              : null,
          style: _elevatedButtonStyle(),
          child: const Text("Proceed to Login"),
        ),
      ],
    );
  }

  Widget _buildPhoneLogin() {
    return Column(
      children: [
        if (!isOtpSent) ...[
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              LengthLimitingTextInputFormatter(10),
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: _inputDecoration("Enter your mobile number")
                .copyWith(
              prefixIcon: const Icon(Icons.phone),
              errorText: errorMessage,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: isLoading ? null : sendOtp,
            style: _elevatedButtonStyle(),
            child: isLoading
                ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Send OTP"),
          ),
          if (errorMessage != null && errorMessage!.contains("not registered"))
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CustomerSignUpScreen()),
                );
              },
              child: const Text("Don't have an account? Sign Up"),
            ),
        ] else ...[
          const Text(
            "Enter the 6-digit code sent to your mobile",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Pinput(
            controller: otpController,
            length: 6,
            defaultPinTheme: PinTheme(
              width: 50,
              height: 50,
              textStyle: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isLoading ? null : verifyOtp,
            style: _elevatedButtonStyle(),
            child: isLoading
                ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Verify OTP"),
          ),
          const SizedBox(height: 10),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser != null) {
      WidgetsBinding.instance?.addPostFrameCallback((_) {
        _checkVerificationStatus();
      });
    }
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: SafeArea(
        child: Stack(
          children: [
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
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                        onPressed: () {
                          if (isOtpSent) {
                            setState(() {
                              isOtpSent = false;
                              errorMessage = null;
                            });
                          } else if (isLocationSelected) {
                            setState(() {
                              isLocationSelected = false;
                              errorMessage = null;
                            });
                          } else {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => LoginScreen())
                              );
                            }
                          }
                        },
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            'FIXIFY USER',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 50),
                    ],
                  ),
                ),
                if (isVerificationApplied)
                  _buildVerificationStatusWidget()
                else
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const SizedBox(height: 20),
                                  Image.asset('assets/images/imagefixify.png', height: 100),
                                  const SizedBox(height: 20),
                                  Text(
                                    !isLocationSelected
                                        ? 'Select Your Location'
                                        : isOtpSent
                                        ? 'Verify OTP'
                                        : 'Login to Your Account',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 40),

                                  if (!isLocationSelected) ...[
                                    _buildLocationSelectors(),
                                    const SizedBox(height: 20),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => PreSignupScreen()),
                                        );
                                      },
                                      child: RichText(
                                        text: const TextSpan(
                                          style: TextStyle(color: Colors.black87),
                                          children: [
                                            TextSpan(text: "Don't have an account? "),
                                            TextSpan(
                                              text: "Sign Up",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ] else
                                    _buildPhoneLogin(),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),

                            if (isLocationSelected && !isOtpSent && !isVerificationApplied)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.yellow[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.shade300),
                                ),
                                child: const Text(
                                  "Unable to login? Ask society to register you",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
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
}
class PreSignupScreen extends StatelessWidget {
  const PreSignupScreen({Key? key}) : super(key: key);

  final String playStoreLink = 'https://play.google.com/store/apps/details?id=com.fixify.app';

  void _shareApp() {
    Share.share(
      'Check out Fixify - Your Society Maintenance App: $playStoreLink',
      subject: 'Fixify - Society Maintenance Made Easy',
    );
  }

  void _navigateToSignup(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CustomerSignUpScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[50],
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -30,
              right: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '9:41',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.signal_cellular_4_bar, size: 16),
                          SizedBox(width: 4),
                          Icon(Icons.wifi, size: 16),
                          SizedBox(width: 4),
                          Icon(Icons.battery_full, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'User',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                Image.asset(
                  'assets/images/imagefixify.png',
                  height: 120,
                ),

                Text(
                  'FIXIFY',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: 40),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.amber[100],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FOR REGISTRATION ENQUIRIES\nWRITE US AT FIXIFY@GMAIL.COM',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 20),

                        // Share button
                        GestureDetector(
                          onTap: _shareApp,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.share, color: Colors.blue[900], size: 18),
                              SizedBox(width: 8),
                              Text(
                                'SHARE FIXIFY',
                                style: TextStyle(
                                  color: Colors.blue[900],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 20),

                        Center(
                          child: Text(
                            'or',
                            style: TextStyle(
                              color: Colors.black54,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        Text(
                          'society/residence representatives',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),

                        SizedBox(height: 16),

                        // Apply Now button
                        GestureDetector(
                          onTap: () => _navigateToSignup(context),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'APPLY NOW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Spacer(),

                // The "Don't find your society? LIST NOW" text has been removed
                // Just adding a small bottom padding for spacing
                SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
