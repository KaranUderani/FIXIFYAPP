import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'CarpentryPage.dart';
import 'ElectricalPage.dart';
import 'HomeInstallationPage.dart';
import 'LocksmithPage.dart';
import 'PaintingPage.dart';
import 'PlumbingPage.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Location data
  String societyName = "";
  String city = "";
  String state = "";
  bool isLoading = true;

  // Define theme colors
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color accentYellow = Color(0xFFFFD54F);
  static const Color backgroundWhite = Color(0xFFF5F7FA);

  // List of all services
  final List<Map<String, dynamic>> services = [
    {"title": "ELECTRICIANS", "icon": "assets/icons/electrical.png", "page": ElectricalPage()},
    {"title": "PLUMBERS", "icon": "assets/icons/plumbing.png", "page": PlumbingPage()},
    {"title": "HOME INSTALLATION", "icon": "assets/icons/home_installation.jpg", "page": HomeInstallationPage()},
    {"title": "PAINTER", "icon": "assets/icons/painting.png", "page": PaintingPage()},
    {"title": "LOCKSMITH", "icon": "assets/icons/locksmith.png", "page": LocksmithPage()},
    {"title": "CARPENTERS", "icon": "assets/icons/carpentry.png", "page": CarpentryPage()},
  ];

  @override
  void initState() {
    super.initState();
    fetchUserLocation();
  }

  // Fetch user location data from Firebase
  Future<void> fetchUserLocation() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('customers')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

          // Access nested data using the structure shown in your Firebase screenshot
          if (userData.containsKey('residenceDetails')) {
            Map<String, dynamic> residenceDetails = userData['residenceDetails'];

            setState(() {
              societyName = residenceDetails['societyName'] ?? "";
              city = residenceDetails['city'] ?? "";
              state = residenceDetails['state'] ?? "";
              isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching user location: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Curved Header with Blue Gradient and Yellow Accent
            Stack(
              children: [
                Container(
                  height: 130,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryBlue, Color(0xFF42A5F5)],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 20,
                  right: 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accentYellow,
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          "assets/images/imagefixify.png",
                          width: 40,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "FIXIFY",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.8,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: Offset(1, 1),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 20,
                  top: 40,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Location Display
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: primaryBlue),
                    SizedBox(width: 12),
                    Expanded(
                      child: isLoading
                          ? Text(
                        "Loading location...",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                          : RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                          children: [
                            TextSpan(
                              text: societyName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryBlue,
                              ),
                            ),
                            TextSpan(text: ", $city, $state"),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 25),

            // Trusted Services Text
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: accentYellow,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "TRUSTED HOME SERVICES NEARBY",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF455A64),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Services Grid
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 0.9,
                  children: services.map((service) {
                    return serviceCard(
                      context,
                      service["title"],
                      service["icon"],
                      service["page"],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Clickable Service Card Widget
  Widget serviceCard(
      BuildContext context,
      String title,
      String imagePath,
      Widget destinationPage,
      ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destinationPage),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
          border: Border.all(color: lightBlue, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: lightBlue,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                imagePath,
                width: 50,
                color: primaryBlue,
              ),
            ),
            SizedBox(height: 15),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF455A64),
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: accentYellow,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}