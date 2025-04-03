import 'package:flutter/material.dart';
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
  String searchQuery = ""; // Stores user search input

  // List of all services
  final List<Map<String, dynamic>> services = [
    {"title": "ELECTRICIANS", "icon": "assets/icons/electrical.png", "page": ElectricalPage()},
    {"title": "PLUMBERS", "icon": "assets/icons/plumbing.png", "page": PlumbingPage()},
    {"title": "HOME INSTALLATION", "icon": "assets/icons/home_installation.png", "page": HomeInstallationPage()},
    {"title": "PAINTER", "icon": "assets/icons/painting.png", "page": PaintingPage()},
    {"title": "LOCKSMITH", "icon": "assets/icons/locksmith.png", "page": LocksmithPage()},
    {"title": "CARPENTERS", "icon": "assets/icons/carpentry.png", "page": CarpentryPage()},
  ];

  @override
  Widget build(BuildContext context) {
    // Filter services based on search query
    List<Map<String, dynamic>> filteredServices = services.where((service) {
      return service["title"].toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Light Yellow Curved Header
            Stack(
              children: [
                Container(
                  height: 120, // Header height
                  decoration: BoxDecoration(
                    color: Color(0xFFFFFFC4), // Light Yellow Background
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                        offset: Offset(0, 3),
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
                      Image.asset(
                        "assets/images/imagefixify.png",
                        width: 50, // Slightly increased size
                      ),
                      SizedBox(width: 12),
                      Text(
                        "FIXIFY",
                        style: TextStyle(
                          fontSize: 28, // Slightly larger text
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.8,
                          color: Colors.black, // Black text for contrast
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Search Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value; // Updates search query dynamically
                  });
                },
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  hintText: "Search For Services...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),

            SizedBox(height: 20),

            // Trusted Services Text
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "TRUSTED HOME SERVICES FROM LOCAL PROVIDERS NEAR YOU:",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ),

            SizedBox(height: 15),

            // Services Grid
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: filteredServices.isEmpty
                    ? Center(
                  child: Text(
                    "No services found",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                )
                    : GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.9,
                  children: filteredServices.map((service) {
                    return serviceCard(context, service["title"], service["icon"], service["page"]);
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
  Widget serviceCard(BuildContext context, String title, String imagePath, Widget destinationPage) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => destinationPage));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(2, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 60), // Increased icon size
            SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
