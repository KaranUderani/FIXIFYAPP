import 'package:flutter/material.dart';
import 'CarpentryPage.dart';
import 'ElectricalPage.dart';
import 'HomeInstallationPage.dart';
import 'LocksmithPage.dart';
import 'PaintingPage.dart';
import 'PlumbingPage.dart'; // Import the Plumbing Page

class ExplorePage extends StatefulWidget {
  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String searchQuery = ""; // Stores the search input

  final List<Map<String, dynamic>> categories = [
    {"name": "Plumbing", "icon": Icons.plumbing},
    {"name": "Electrician", "icon": Icons.electrical_services},
    {"name": "Home Installation", "icon": Icons.cleaning_services},
    {"name": "Carpenter", "icon": Icons.carpenter},
    {"name": "Locksmith", "icon": Icons.lock},
    {"name": "Painting", "icon": Icons.format_paint},
  ];

  final List<Map<String, dynamic>> topProfessionals = [
    {"name": "David Miller", "service": "Plumbing", "image": "assets/images/profile image.png"},
    {"name": "Emma Johnson", "service": "Home Cleaning", "image": "assets/images/profile image.png"},
    {"name": "John Doe", "service": "Electrician", "image": "assets/images/profile image.png"},
  ];

  final List<String> offers = [
    "20% OFF on Home Cleaning!",
    "Flat ₹100 OFF on Carpentry",
    "Special Discount on First Booking!"
  ];

  final List<Map<String, dynamic>> recentlyViewed = [
    {"name": "Alice Green", "service": "Locksmith", "image": "assets/images/profile image.png"},
    {"name": "Mark Taylor", "service": "Painting", "image": "assets/images/profile image.png"},
  ];

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    List<Map<String, dynamic>> filteredCategories = categories.where((category) {
      return category["name"].toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Explore Services", style: TextStyle(fontSize: screenWidth * 0.05)),
        backgroundColor: Color(0xFFFFFFC4),
        centerTitle: true,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            SizedBox(height: screenWidth * 0.05),

            _buildSectionTitle("🔥 Ongoing Offers"),
            _buildOffersSection(),

            _buildSectionTitle("🛠 Service Categories"),
            _buildServiceCategories(filteredCategories),

            _buildSectionTitle("⭐ Featured Professionals"),
            _buildHorizontalList(topProfessionals),

            _buildSectionTitle("🔄 Recently Viewed"),
            Column(
              children: recentlyViewed.map((worker) => _buildProfessionalCard(worker)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // 🔍 Search Bar
  Widget _buildSearchBar() {
    return TextField(
      onChanged: (value) => setState(() => searchQuery = value),
      decoration: InputDecoration(
        hintText: "Search for services...",
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // 📢 Offers Section
  Widget _buildOffersSection() {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: offers.length,
        itemBuilder: (context, index) {
          return Container(
            width: 200,
            margin: EdgeInsets.only(right: 10),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.yellow[700],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                offers[index],
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }

  // 🛠 Service Categories Grid
  Widget _buildServiceCategories(List<Map<String, dynamic>> filteredCategories) {
    if (filteredCategories.isEmpty) {
      return Center(child: Text("No services found", style: TextStyle(fontSize: 16, color: Colors.black54)));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: filteredCategories.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _navigateToService(filteredCategories[index]["name"]),
          child: Column(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.black54,
                child: Icon(filteredCategories[index]["icon"], size: 30, color: Colors.white),
              ),
              SizedBox(height: 5),
              Text(filteredCategories[index]["name"], style: TextStyle(fontSize: 14)),
            ],
          ),
        );
      },
    );
  }

  // ⭐ Featured Professionals & Recently Viewed List
  Widget _buildHorizontalList(List<Map<String, dynamic>> professionals) {
    return Container(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: professionals.length,
        itemBuilder: (context, index) {
          return _buildProfessionalCard(professionals[index]);
        },
      ),
    );
  }

  // 🔥 Professional Card
  Widget _buildProfessionalCard(Map<String, dynamic> worker) {
    return Container(
      width: 150,
      margin: EdgeInsets.only(right: 10, bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 5, spreadRadius: 2)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(radius: 30, backgroundImage: AssetImage(worker["image"])),
          SizedBox(height: 10),
          Text(worker["name"], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(worker["service"], style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  // 📌 Section Title
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  // 🚀 Navigate to Service Pages
  void _navigateToService(String serviceName) {
    Map<String, Widget> servicePages = {
      "Plumbing": PlumbingPage(),
      "Electrician": ElectricalPage(),
      "Home Installation": HomeInstallationPage(),
      "Carpenter": CarpentryPage(),
      "Locksmith": LocksmithPage(),
      "Painting": PaintingPage(),
    };

    if (servicePages.containsKey(serviceName)) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => servicePages[serviceName]!));
    }
  }
}
