import 'package:flutter/material.dart';

class CarpentryPage extends StatelessWidget {
  final List<Map<String, dynamic>> carpenters = [
    {"name": "James Wood", "experience": "10 years", "rating": 4.9, "image": "assets/images/profile image.png", "phone": "123-456-7890", "address": "123 Maple St, City", "type": "Professional Carpenter", "available": true},
    {"name": "Emily Brown", "experience": "6 years", "rating": 4.7, "image": "assets/images/profile image.png", "phone": "987-654-3210", "address": "456 Oak St, City", "type": "Freelance Carpenter", "available": false},
    {"name": "Robert Carter", "experience": "8 years", "rating": 4.8, "image": "assets/images/profile image.png", "phone": "555-123-4567", "address": "789 Pine St, City", "type": "Senior Carpenter", "available": true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Carpenters", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.red[300],
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
          itemCount: carpenters.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CarpenterDetailsPage(carpenter: carpenters[index]),
                ),
              ),
              child: _buildCarpenterCard(carpenters[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCarpenterCard(Map<String, dynamic> worker) {
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
              color: Colors.red[600],
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

class CarpenterDetailsPage extends StatelessWidget {
  final Map<String, dynamic> carpenter;

  CarpenterDetailsPage({required this.carpenter});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Carpenter Details"),
        backgroundColor: Colors.red[300],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundImage: AssetImage(carpenter["image"]),
            ),
            SizedBox(height: 20),
            Text(carpenter["name"], style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 24),
                SizedBox(width: 4),
                Text(carpenter["rating"].toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 10),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Phone: ${carpenter["phone"]}", style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text("Address: ${carpenter["address"]}", style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text("Type: ${carpenter["type"]}", style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          carpenter["available"] ? Icons.check_circle : Icons.cancel,
                          color: carpenter["available"] ? Colors.green : Colors.red,
                          size: 30,
                        ),
                        SizedBox(width: 10),
                        Text(
                          carpenter["available"] ? "Available" : "Not Available",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: carpenter["available"] ? () {} : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[300],
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Book Carpenter", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}