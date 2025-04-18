import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter/services.dart';
import 'package:fixifypartner/partner/dash/screens/dashboard.dart';
import 'package:fixifypartner/partner/authentication/screens/signup_screen.dart';
/*import 'package:fixifypartner/partner/authentication/screens/login_screen.dart'; */

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  bool isLoading = false;
  bool otpSent = false;
  String? verificationId;
  String? errorMessage;
  int resendTimer = 30;
  bool canResend = false;

  void _startResendTimer() {
    setState(() {
      resendTimer = 30;
      canResend = false;
    });

    for (int i = 0; i < 30; i++) {
      Future.delayed(Duration(seconds: i), () {
        if (mounted) {
          setState(() {
            resendTimer--;
            if (resendTimer == 0) canResend = true;
          });
        }
      });
    }
  }

  Future<bool> _checkUserExists(String phoneNumber) async {
    try {
      // Step 1: Format the phone number consistently
      String formattedPhone = _formatPhoneNumber(phoneNumber);

      // Step 2: Debug print to verify the formatted number
      print('Checking for phone: $formattedPhone');

      // Step 3: Query Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('users') // Make sure this matches your collection name
          .where('phone', isEqualTo: formattedPhone) // Make sure 'phone' matches your field name
          .limit(1)
          .get();

      // Step 4: Debug print results
      print('Query results: ${snapshot.docs.length} matches');
      if (snapshot.docs.isNotEmpty) {
        print('Found user: ${snapshot.docs.first.id}');
      }

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error in _checkUserExists: $e');
      return false;
    }
  }

  String _formatPhoneNumber(String rawNumber) {
    // Remove all non-digit characters
    String digits = rawNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // Add country code if missing (assuming India +91)
    if (!digits.startsWith('91') && digits.length == 10) {
      digits = '91$digits';
    }

    return '+$digits';
  }

  Future<void> _verifyPhoneNumber() async {
    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    try {
      final formattedPhone = _formatPhoneNumber(phoneController.text);
      print('Verifying phone: $formattedPhone');

      // First check if user exists
      final userExists = await _checkUserExists(formattedPhone);
      print('User exists: $userExists');

      if (!userExists) {
        setState(() {
          isLoading = false;
          errorMessage = 'This phone number is not registered. Please sign up first.';
        });
        return;
      }

      // If user exists, send OTP
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          );
        },
        verificationFailed: (e) {
          setState(() {
            isLoading = false;
            errorMessage = 'Verification failed: ${e.message}';
          });
        },
        codeSent: (verificationId, resendToken) {
          setState(() {
            this.verificationId = verificationId;
            isLoading = false;
            otpSent = true;
          });
          _startResendTimer();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          this.verificationId = verificationId;
        },
        timeout: Duration(seconds: 60),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _verifyOTP() async {
    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otpController.text.trim(),
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // Check if the user is signed in successfully
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to sign in. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Invalid OTP. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF9C4), // Light yellow background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24),
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 40),

                // Logo and Brand
                Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/images/imagefixify.png',
                    width: 120,
                    height: 120,
                  ),
                ),

                SizedBox(height: 16),

                Text(
                  "FIXIFY",
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: Colors.black87
                  ),
                ),
                Text(
                  "P A R T N E R",
                  style: TextStyle(
                      fontSize: 16,
                      letterSpacing: 2.0,
                      color: Colors.black54
                  ),
                ),

                SizedBox(height: 40),

                // Animated Card for Authentication
                AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4)
                        )
                      ]
                  ),
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (!otpSent) ...[
                        // Phone Number Input
                        TextField(
                          controller: phoneController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.phone, color: Colors.black54),
                            labelText: 'Phone Number',
                            hintText: 'Enter your registered phone number',
                            errorText: errorMessage,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.black26)
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
                        ),

                        SizedBox(height: 24),

                        // Get Verification Button
                        ElevatedButton(
                          onPressed: _verifyPhoneNumber,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25)
                              )
                          ),
                          child: isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text("Get Verification Code", style: TextStyle(fontSize: 12)),
                        ),
                      ] else ...[
                        // OTP Input Section
                        Text(
                          "Verify Your Number",
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87
                          ),
                        ),

                        SizedBox(height: 12),

                        Text(
                          "Enter the 6-digit code sent to ${_formatPhoneNumber(phoneController.text)}",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),

                        SizedBox(height: 24),

                        // Pinput for OTP
                        Pinput(
                          controller: otpController,
                          length: 6,
                          defaultPinTheme: PinTheme(
                            width: 50,
                            height: 50,
                            textStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black26),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        SizedBox(height: 20),

                        // Resend OTP
                        GestureDetector(
                          onTap: canResend ? _verifyPhoneNumber : null,
                          child: Text(
                            canResend ? "Resend Code" : "Resend in $resendTimer sec",
                            style: TextStyle(
                                color: canResend ? Colors.blue : Colors.black54,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),

                        SizedBox(height: 24),

                        // Verify OTP Button
                        ElevatedButton(
                          onPressed: _verifyOTP,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 80),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)
                              )
                          ),
                          child: isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text('Verify OTP', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 80),

                // Sign Up Navigation
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpScreen()));
                  },
                  child: RichText(
                    text: TextSpan(
                        style: TextStyle(color: Colors.black),
                        children: [
                          TextSpan(text: "New to FIXIFY? "),
                          TextSpan(
                              text: "SIGN UP",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue
                              )
                          )
                        ]
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}