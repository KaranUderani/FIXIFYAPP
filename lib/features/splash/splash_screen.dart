/*import 'package:flutter/material.dart';
import 'package:fixifypartner/features/authentication/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
       MaterialPageRoute(builder: (context) => LoginScreen()), // Navigate to Login
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[300],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/imagefixify.png",
              height: 200,
              width: 200,
            ),
            SizedBox(height: 20),
            Text(
              'FIXIFY',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Your Trusted Home Service Partner!',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Roboto',
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Quick . Affordable . Trusted',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/


import 'package:flutter/material.dart';
import 'package:fixifypartner/features/dash/screens/dashboard.dart';
import 'package:fixifypartner/features/authentication/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';


class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), () {
      FirebaseAuth auth = FirebaseAuth.instance;
      User? user = auth.currentUser;

      if (user != null) {
        // User is logged in, navigate to Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardScreen()),
        );
      } else {
        // User not logged in, navigate to Login Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    }); // Added missing closing bracket here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[300],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/imagefixify.png",
              height: 200,
              width: 200,
            ),
            SizedBox(height: 20),
            Text(
              'FIXIFY',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                fontFamily: 'Roboto',
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Your Trusted Home Service Partner!',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'Roboto',
              ),
            ),
            SizedBox(height: 5),
            Text(
              'Quick . Affordable . Trusted',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
      ),
    );
  }
}