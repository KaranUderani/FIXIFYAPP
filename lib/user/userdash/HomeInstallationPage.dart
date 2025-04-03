import 'package:flutter/material.dart';

class HomeInstallationPage extends StatelessWidget {
  final List<Map<String, dynamic>> installers = [
    {
      "name": "David Miller",
      "experience": "6 years",
      "rating": 4.9,
      "image": "assets/images/profile image.png",
      "phone": "+1234567890",
      "address": "123 Main St, NY",
      "type": "Home Installer",
      "available": true,
    },
    {
      "name": "Emma Johnson",
      "experience": "4 years",
      "rating": 4.6,
      "image": "assets/images/profile image.png",
      "phone": "+9876543210",
      "address": "456 Oak Ave, CA",
      "type": "Home Installer",
      "available": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Home Installers Available", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.yellow[300],
        centerTitle: true,
        elevation: 4,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: GridView.builder(
          physics: BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: installers.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PartnerDetailPage(partner: installers[index]),
                  ),
                );
              },
              child: _buildInstallerCard(installers[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInstallerCard(Map<String, dynamic> worker) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade300, blurRadius: 10, spreadRadius: 2, offset: Offset(-2, -2)),
          BoxShadow(color: Colors.grey.shade400, blurRadius: 10, spreadRadius: 2, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage(worker["image"]),
          ),
          SizedBox(height: 10),
          Text(worker["name"], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text(worker["experience"], style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.yellow[600],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star, color: Colors.white, size: 18),
                SizedBox(width: 4),
                Text(worker["rating"].toString(), style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PartnerDetailPage extends StatelessWidget {
  final Map<String, dynamic> partner;
  PartnerDetailPage({required this.partner});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(partner["name"]),
        backgroundColor: Colors.yellow[300],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage(partner["image"]),
            ),
            SizedBox(height: 10),
            Text(partner["name"], style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text("Phone: ${partner["phone"]}", style: TextStyle(fontSize: 16)),
            Text("Address: ${partner["address"]}", style: TextStyle(fontSize: 16)),
            Text("Type: ${partner["type"]}", style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Availability: ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Icon(
                  partner["available"] ? Icons.check_circle : Icons.cancel,
                  color: partner["available"] ? Colors.green : Colors.red,
                  size: 24,
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: Text("Book Partner"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow[600],
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}