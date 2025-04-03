import 'package:flutter/material.dart';

class ElectricalPage extends StatelessWidget {
  final List<Map<String, dynamic>> electricians = [
    {"name": "David Miller", "experience": "6 years", "rating": 4.9, "image": "assets/images/profile image.png", "phone": "123-456-7890", "address": "123 Main St, City", "type": "Professional Painter", "available": true},
    {"name": "David Miller", "experience": "6 years", "rating": 4.9, "image": "assets/images/profile image.png", "phone": "123-456-7890", "address": "123 Main St, City", "type": "Professional Painter", "available": true},
    {"name": "David Miller", "experience": "6 years", "rating": 4.9, "image": "assets/images/profile image.png", "phone": "123-456-7890", "address": "123 Main St, City", "type": "Professional Painter", "available": true},
    {"name": "David Miller", "experience": "6 years", "rating": 4.9, "image": "assets/images/profile image.png", "phone": "123-456-7890", "address": "123 Main St, City", "type": "Professional Painter", "available": true},
    {"name": "Emma Johnson", "experience": "4 years", "rating": 4.6, "image": "assets/images/profile image.png", "phone": "987-654-3210", "address": "456 Elm St, City", "type": "Freelance Painter", "available": false},
    {"name": "Emma Johnson", "experience": "4 years", "rating": 4.6, "image": "assets/images/profile image.png", "phone": "987-654-3210", "address": "456 Elm St, City", "type": "Freelance Painter", "available": false},
    {"name": "Emma Johnson", "experience": "4 years", "rating": 4.6, "image": "assets/images/profile image.png", "phone": "987-654-3210", "address": "456 Elm St, City", "type": "Freelance Painter", "available": false},
    {"name": "Emma Johnson", "experience": "4 years", "rating": 4.6, "image": "assets/images/profile image.png", "phone": "987-654-3210", "address": "456 Elm St, City", "type": "Freelance Painter", "available": false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Electricians", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.orange[300],
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
          itemCount: electricians.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ElectricianDetailsPage(electrician: electricians[index]),
                ),
              ),
              child: _buildElectricianCard(electricians[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildElectricianCard(Map<String, dynamic> worker) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.amber, size: 20),
              SizedBox(width: 4),
              Text(worker["rating"].toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class ElectricianDetailsPage extends StatelessWidget {
  final Map<String, dynamic> electrician;

  ElectricianDetailsPage({required this.electrician});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Electrician Details"),
        backgroundColor: Colors.orange[300],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 80,
              backgroundImage: AssetImage(electrician["image"]),
            ),
            SizedBox(height: 20),
            Text(electrician["name"], style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 24),
                SizedBox(width: 4),
                Text(electrician["rating"].toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    Text("Phone: ${electrician["phone"]}", style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text("Address: ${electrician["address"]}", style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text("Type: ${electrician["type"]}", style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          electrician["available"] ? Icons.check_circle : Icons.cancel,
                          color: electrician["available"] ? Colors.green : Colors.red,
                          size: 30,
                        ),
                        SizedBox(width: 10),
                        Text(
                          electrician["available"] ? "Available" : "Not Available",
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
              onPressed: electrician["available"] ? () {} : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[300],
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Book Electrician", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
