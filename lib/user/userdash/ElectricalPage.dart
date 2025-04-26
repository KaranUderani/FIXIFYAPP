import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ElectricalPage extends StatefulWidget {
  @override
  _ElectricalPageState createState() => _ElectricalPageState();
}

class _ElectricalPageState extends State<ElectricalPage> {
  late Stream<QuerySnapshot> _electriciansStream;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Query Firestore for users with partnerType 'Electrician'
    _electriciansStream = FirebaseFirestore.instance
        .collection('users')
        .where('partnerType', isEqualTo: 'Electrician')
        .snapshots();
  }

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
        child: StreamBuilder<QuerySnapshot>(
          stream: _electriciansStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Something went wrong'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No electricians found'));
            }

            return GridView.builder(
              physics: BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var electricianData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ElectricianDetailsPage(electrician: electricianData),
                    ),
                  ),
                  child: _buildElectricianCard(electricianData),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildElectricianCard(Map<String, dynamic> worker) {
    // Default values if data is missing
    String name = worker["name"] ?? "Unknown";
    String experience = worker["experience"] ?? "Not specified";
    double rating = worker["rating"]?.toDouble() ?? 0.0;
    String imageUrl = worker["profileImage"] ?? "assets/images/profile image.png";

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
            backgroundImage: imageUrl.startsWith('http')
                ? NetworkImage(imageUrl) as ImageProvider
                : AssetImage(imageUrl),
            backgroundColor: Colors.grey[300],
          ),
          SizedBox(height: 10),
          Text(name,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
          SizedBox(height: 5),
          Text(experience,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: Colors.amber, size: 20),
              SizedBox(width: 4),
              Text(rating.toString(), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    // Extract values with null safety
    String name = electrician["name"] ?? "Unknown";
    String phone = electrician["phone"] ?? "Not available";
    String city = electrician["city"] ?? "Not specified";
    String state = electrician["state"] ?? "";
    String address = "$city, $state";
    String partnerType = electrician["partnerType"] ?? "Electrician";
    bool available = electrician["available"] ?? false;
    double rating = electrician["rating"]?.toDouble() ?? 0.0;
    String imageUrl = electrician["profileImage"] ?? "assets/images/profile image.png";
    String serviceRadius = electrician["serviceRadius"] ?? "Not specified";

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
              backgroundImage: imageUrl.startsWith('http')
                  ? NetworkImage(imageUrl) as ImageProvider
                  : AssetImage(imageUrl),
              backgroundColor: Colors.grey[300],
            ),
            SizedBox(height: 20),
            Text(name, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 24),
                SizedBox(width: 4),
                Text(rating.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                    Text("Phone: $phone", style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text("Location: $address", style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text("Service Area: $serviceRadius", style: TextStyle(fontSize: 18)),
                    SizedBox(height: 8),
                    Text("Type: $partnerType", style: TextStyle(fontSize: 18)),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          available ? Icons.check_circle : Icons.cancel,
                          color: available ? Colors.green : Colors.red,
                          size: 30,
                        ),
                        SizedBox(width: 10),
                        Text(
                          available ? "Available" : "Not Available",
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
              onPressed: available ? () {
                // Implement booking functionality
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Booking request sent to $name"))
                );
              } : null,
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