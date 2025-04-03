import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'ThemeScreen.dart';
import 'RateUsScreen.dart';
import 'package:fixifypartner/features/authentication/screens/login_screen.dart';
import 'ContactUsScreen.dart';
import 'EditProfileScreen.dart';
import 'HomeScreen.dart';
import 'ExplorePage.dart';
import 'Bookings.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "FIXIFY";
  String userEmail = "fixify@gmail.com";
  String userPhone = "+91 1234567890";
  final String appLink = "https://fixifyapp.com"; // Replace with actual app link

  int _selectedIndex = 3; // Default to Profile tab

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return; // Prevent reloading the same page

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = HomeScreen();
        break;
      case 1:
        nextScreen = ExplorePage();
        break;
      case 2:
        nextScreen = Bookings();
        break;
      case 3:
        nextScreen = ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5FF),
      appBar: AppBar(
        title: Text(
          "Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Header Section
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 6),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[300],
                    child: ClipOval(
                      child: Image.asset(
                        "assets/images/imagefixify.png",
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(userPhone, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            name: userName,
                            email: userEmail,
                            phone: userPhone,
                          ),
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          userName = result["name"];
                          userEmail = result["email"];
                          userPhone = result["phone"];
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Profile Menu Options
            ProfileOption(
              icon: Icons.color_lens,
              text: "Theme",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ThemeScreen()));
              },
            ),
            ProfileOption(
              icon: Icons.share,
              text: "Share And Explore",
              onTap: () {
                _shareApp();
              },
            ),
            ProfileOption(
              icon: Icons.star,
              text: "Rate us",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => RateUsScreen()));
              },
            ),
            ProfileOption(
              icon: Icons.contact_mail,
              text: "Contact Us",
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ContactUsScreen()));
              },
            ),

            SizedBox(height: 10),

            // Logout Button with Different Styling
            Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  _showLogoutConfirmation(context);
                },
                child: Text("Logout", style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),

    );
  }

  // Share App Function
  void _shareApp() {
    Share.share("Check out Fixify App! Download now: $appLink");
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Logout"),
        content: Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) =>   LoginScreen()),
              );
            },
            child: Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Custom Profile Menu Option Widget
class ProfileOption extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  ProfileOption({required this.icon, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: Colors.blue, size: 28),
        title: Text(text, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}