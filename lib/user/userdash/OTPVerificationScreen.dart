import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pinput/pinput.dart';
class OTPVerificationScreen extends StatefulWidget {
  final String type; // "Email" or "Phone"

  OTPVerificationScreen({required this.type});

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  bool _isLoading = false;
  bool _canResend = false;
  int _secondsRemaining = 30;
  Timer? _timer;
  String _enteredOTP = "";

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 30;
    _canResend = false;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      }
    });
  }

  void _verifyOTP() {
    setState(() {
      _isLoading = true;
    });

    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });

      if (_enteredOTP == "123456") { // Mock verification
        Navigator.pop(context, true); // Success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invalid OTP!")),
        );
      }
    });
  }

  void _resendOTP() {
    setState(() {
      _canResend = false;
    });
    _startTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("New OTP sent to your ${widget.type}")),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Verify ${widget.type}",
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text(
              "Enter the OTP sent to your ${widget.type}",
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),

            // OTP Input Field
            Pinput(
              length: 6,
              showCursor: true,
              onChanged: (otp) {
                setState(() {
                  _enteredOTP = otp;
                });
              },
              onCompleted: (otp) {
                setState(() {
                  _enteredOTP = otp;
                });
              },
            ),


            SizedBox(height: 20),

            // Verify Button
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _enteredOTP.length == 6 ? _verifyOTP : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                "Verify",
              ),
            ),

            SizedBox(height: 20),

            // Resend OTP
            _canResend
                ? TextButton(
              onPressed: _resendOTP,
              child: Text(
                "Resend OTP",
              ),
            )
                : Text(
              "Resend OTP in $_secondsRemaining sec",
            ),
          ],
        ),
      ),
    );
  }
}
