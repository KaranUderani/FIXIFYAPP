import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class PlumbingPage extends StatefulWidget {
  @override
  _PlumbingPageState createState() => _PlumbingPageState();
}

class _PlumbingPageState extends State<PlumbingPage> {
  late Stream<QuerySnapshot> _plumbersStream;
  bool isLoading = true;
  Map<String, dynamic>? currentUserData;
  List<Map<String, dynamic>> availableInRangePlumbers = [];
  List<Map<String, dynamic>> unavailableInRangePlumbers = [];
  List<Map<String, dynamic>> outOfRangePlumbers = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
    // Get all plumbers initially
    _plumbersStream = FirebaseFirestore.instance
        .collection('users')
        .where('partnerType', isEqualTo: 'Plumber')
        .snapshots();
  }

  // Load the current customer's location data
  Future<void> _loadCurrentUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get current user ID
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        // If not found in auth, try getting from phone number
        String? phoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber;

        if (phoneNumber != null) {
          // Try to find user by phone number in customers collection
          var querySnapshot = await FirebaseFirestore.instance
              .collection('customers')
              .where('phone', isEqualTo: phoneNumber)
              .limit(1)
              .get();

          if (querySnapshot.docs.isNotEmpty) {
            currentUserData = querySnapshot.docs.first.data() as Map<String, dynamic>;
          }
        }
      } else {
        // Get user data from customers collection
        var docSnapshot = await FirebaseFirestore.instance
            .collection('customers')
            .doc(userId)
            .get();

        if (docSnapshot.exists) {
          currentUserData = docSnapshot.data() as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Calculate distance between two points using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Radius of the earth in km

    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    double distance = earthRadius * c; // Distance in km

    return distance;
  }

  double _degToRad(double deg) {
    return deg * (pi / 180);
  }

  void _filterPlumbers(List<QueryDocumentSnapshot> plumberDocs) {
    availableInRangePlumbers.clear();
    unavailableInRangePlumbers.clear();
    outOfRangePlumbers.clear();

    if (currentUserData == null) {
      // If no user data, put all in out of range
      for (var doc in plumberDocs) {
        var data = doc.data() as Map<String, dynamic>;
        outOfRangePlumbers.add(data);
      }
      return;
    }

    // Get customer location
    double? customerLat, customerLng;

    if (currentUserData!.containsKey('residenceDetails') &&
        currentUserData!['residenceDetails'].containsKey('location')) {
      customerLat = currentUserData!['residenceDetails']['location']['latitude']?.toDouble();
      customerLng = currentUserData!['residenceDetails']['location']['longitude']?.toDouble();
    } else if (currentUserData!.containsKey('locationDetails')) {
      customerLat = currentUserData!['locationDetails']['latitude']?.toDouble();
      customerLng = currentUserData!['locationDetails']['longitude']?.toDouble();
    }

    if (customerLat == null || customerLng == null) {
      // If customer location not available, categorize based only on availability
      for (var doc in plumberDocs) {
        var data = doc.data() as Map<String, dynamic>;
        bool isAvailable = data['isAvailable'] ?? false;

        if (isAvailable) {
          availableInRangePlumbers.add(data);
        } else {
          unavailableInRangePlumbers.add(data);
        }
      }
      return;
    }

    // Filter plumbers based on location and availability
    for (var doc in plumberDocs) {
      var data = doc.data() as Map<String, dynamic>;
      bool isAvailable = data['isAvailable'] ?? false;
      double plumberLat = 0.0;
      double plumberLng = 0.0;
      double serviceRadiusKm = 0.5; // Default smaller value, was 5.0 before

      // Extract location data
      if (data.containsKey('locationDetails')) {
        plumberLat = data['locationDetails']['latitude']?.toDouble() ?? 0.0;
        plumberLng = data['locationDetails']['longitude']?.toDouble() ?? 0.0;
      }

      // Extract service radius
      if (data.containsKey('serviceRadius') && data['serviceRadius'] != null) {
        String radiusStr = data['serviceRadius'] as String;
        print('Parsing service radius: "$radiusStr"');

        // Parse radius from string like "Up to 0.5 km" or "Up to 1 km"
        if (radiusStr.contains("0.5")) {
          serviceRadiusKm = 0.5;
        } else if (radiusStr.contains("1")) {
          serviceRadiusKm = 1.0;
        } else if (radiusStr.contains("2")) {
          serviceRadiusKm = 2.0;
        } else if (radiusStr.contains("5")) {
          serviceRadiusKm = 5.0;
        } else {
          // Try to extract any numeric value if it doesn't match the expected patterns
          radiusStr = radiusStr.replaceAll(RegExp(r'[^0-9.]'), '');
          try {
            double parsedValue = double.parse(radiusStr);
            if (parsedValue > 0) {
              serviceRadiusKm = parsedValue;
            }
          } catch (e) {
            print('Failed to parse radius value: $e');
            // Keep the default 0.5 km if parsing fails
          }
        }
      }

      double distance = calculateDistance(
          customerLat,
          customerLng,
          plumberLat,
          plumberLng
      );

      // Add debug printing
      print('Plumber: ${data['name']}');
      print('Customer: $customerLat, $customerLng');
      print('Plumber: $plumberLat, $plumberLng');
      print('Calculated distance: $distance km');
      print('Service radius: $serviceRadiusKm km');
      print('Within radius: ${distance <= serviceRadiusKm}');

      // Add calculated distance to plumber data
      data['distance'] = distance.toStringAsFixed(1);

      // Check if customer is within service radius
      bool isWithinRadius = distance <= serviceRadiusKm;

      // Categorize plumbers into three groups
      if (isWithinRadius) {
        if (isAvailable) {
          availableInRangePlumbers.add(data);
        } else {
          unavailableInRangePlumbers.add(data);
        }
      } else {
        outOfRangePlumbers.add(data);
      }
    }

    // Sort all lists by distance
    availableInRangePlumbers.sort((a, b) {
      double distA = double.tryParse(a['distance'] ?? '0.0') ?? 0.0;
      double distB = double.tryParse(b['distance'] ?? '0.0') ?? 0.0;
      return distA.compareTo(distB);
    });

    unavailableInRangePlumbers.sort((a, b) {
      double distA = double.tryParse(a['distance'] ?? '0.0') ?? 0.0;
      double distB = double.tryParse(b['distance'] ?? '0.0') ?? 0.0;
      return distA.compareTo(distB);
    });

    outOfRangePlumbers.sort((a, b) {
      double distA = double.tryParse(a['distance'] ?? '0.0') ?? 0.0;
      double distB = double.tryParse(b['distance'] ?? '0.0') ?? 0.0;
      return distA.compareTo(distB);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Plumbers",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.blue[300],
        centerTitle: true,
        elevation: 4,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
        stream: _plumbersStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No plumbers found'));
          }

          // Filter plumbers based on location
          _filterPlumbers(snapshot.data!.docs);

          return SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer location information
                if (currentUserData != null)
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.blue[300]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Showing results for: ${_getCustomerAddress()}",
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Available In Range Plumbers Section
                Text(
                  "Available (In Range) - ${availableInRangePlumbers.length}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                SizedBox(height: 12),
                availableInRangePlumbers.isEmpty
                    ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text("No available plumbers in your area"),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: availableInRangePlumbers.length,
                  itemBuilder: (context, index) {
                    return _buildPlumberListItem(
                      availableInRangePlumbers[index],
                      status: "Available",
                    );
                  },
                ),

                SizedBox(height: 24),

                // Unavailable In Range Plumbers Section
                Text(
                  "Unavailable (In Range) - ${unavailableInRangePlumbers.length}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                SizedBox(height: 12),
                unavailableInRangePlumbers.isEmpty
                    ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text("No unavailable plumbers in your area"),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: unavailableInRangePlumbers.length,
                  itemBuilder: (context, index) {
                    return _buildPlumberListItem(
                      unavailableInRangePlumbers[index],
                      status: "Unavailable",
                    );
                  },
                ),

                SizedBox(height: 24),

                // Out of Range Plumbers Section
                Text(
                  "Out of Range - ${outOfRangePlumbers.length}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 12),
                outOfRangePlumbers.isEmpty
                    ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text("No plumbers out of range"),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: outOfRangePlumbers.length,
                  itemBuilder: (context, index) {
                    return _buildPlumberListItem(
                      outOfRangePlumbers[index],
                      status: "Out of Range",
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getCustomerAddress() {
    if (currentUserData == null) return "Unknown location";

    String city = "";
    String state = "";

    if (currentUserData!.containsKey('residenceDetails')) {
      city = currentUserData!['residenceDetails']['city'] ?? "";
      state = currentUserData!['residenceDetails']['state'] ?? "";
    } else if (currentUserData!.containsKey('locationDetails')) {
      city = currentUserData!['locationDetails']['city'] ?? "";
      state = currentUserData!['locationDetails']['state'] ?? "";
    }

    return city.isNotEmpty ? "$city, $state" : "Unknown location";
  }

  Widget _buildPlumberListItem(Map<String, dynamic> plumber,
      {required String status}) {
    // Extract data with defaults
    String name = plumber["name"] ?? "Unknown";
    String experience = plumber["experience"] ?? "Not specified";
    String imageUrl = plumber["profileImage"] ??
        "assets/images/profile image.png";
    String distance = plumber["distance"] ?? "Unknown";
    bool isVerified = plumber["verificationStatus"] == "verified";
    bool isAvailable = status == "Available";

    // Set color based on status
    Color statusColor;
    Color bgColor;

    switch (status) {
      case "Available":
        statusColor = Colors.green[800]!;
        bgColor = Colors.green[100]!;
        break;
      case "Unavailable":
        statusColor = Colors.red[800]!;
        bgColor = Colors.red[100]!;
        break;
      case "Out of Range":
        statusColor = Colors.grey[800]!;
        bgColor = Colors.grey[100]!;
        break;
      default:
        statusColor = Colors.grey[800]!;
        bgColor = Colors.grey[100]!;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () =>
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PlumberDetailsPage(plumber: plumber),
              ),
            ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile Image with Verification Badge
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: imageUrl.startsWith('http')
                            ? NetworkImage(imageUrl) as ImageProvider
                            : AssetImage(imageUrl),
                        backgroundColor: Colors.grey[300],
                      ),
                      if (isVerified)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(Icons.verified, size: 16,
                                color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      name,
                                      style: TextStyle(fontSize: 20,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    if (isVerified) SizedBox(width: 4),
                                    if (isVerified)
                                      Icon(Icons.verified, size: 16,
                                          color: Colors.blue),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  experience,
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            if (isAvailable)
                              ElevatedButton(
                                onPressed: () {
                                  // Book this plumber
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(
                                          "Booking request sent to $name"))
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[300],
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  "Book",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white),
                                ),
                              )
                            else if (status == "Unavailable")
                              ElevatedButton(
                                onPressed: () {
                                  // Book for later option
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(
                                          "Added $name to your future bookings"))
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[300],
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  "Book for Later",
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Distance info
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 14,
                                    color: Colors.blue[700]),
                                SizedBox(width: 4),
                                Text(
                                  "$distance km away",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.blue[700]),
                                ),
                              ],
                            ),

                            // Status indicator
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: statusColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Verification badge text
              if (isVerified)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(Icons.verified_user, size: 14, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        "Verified Professional",
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlumberDetailsPage extends StatelessWidget {
  final Map<String, dynamic> plumber;

  PlumberDetailsPage({required this.plumber});

  @override
  Widget build(BuildContext context) {
    // Extract values with null safety
    String name = plumber["name"] ?? "Unknown";
    String partnerType = plumber["partnerType"] ?? "Plumber";
    bool available = plumber["isAvailable"] ?? false;
    bool isVerified = plumber["verificationStatus"] == "verified";
    String verificationDate = plumber["verificationDate"] ?? "";

    // Store the actual rating value
    double? ratingValue = plumber["rating"]?.toDouble();

    // Display text for rating - either the actual value or "no ratings available"
    String ratingDisplay = ratingValue != null ? ratingValue.toString() : "no ratings available";

    String imageUrl = plumber["profileImage"] ?? "assets/images/profile image.png";
    String distance = plumber["distance"] ?? "Unknown";
    String experience = plumber["experience"] ?? "Not specified";

    return Scaffold(
      appBar: AppBar(
        title: Text("Plumber Details"),
        backgroundColor: Colors.blue[300],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image with Verification Badge
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundImage: imageUrl.startsWith('http')
                      ? NetworkImage(imageUrl) as ImageProvider
                      : AssetImage(imageUrl),
                  backgroundColor: Colors.grey[300],
                ),
                if (isVerified)
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(Icons.verified, size: 24, color: Colors.white),
                  ),
              ],
            ),
            SizedBox(height: 20),

            // Name with Verification Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                if (isVerified) SizedBox(width: 8),
                if (isVerified) Icon(Icons.verified, size: 24, color: Colors.blue),
              ],
            ),

            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: Colors.amber, size: 24),
                SizedBox(width: 4),
                Text(ratingDisplay,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            SizedBox(height: 10),

            // Distance chip
            if (distance != "Unknown")
              Chip(
                backgroundColor: Colors.blue[100],
                avatar: Icon(Icons.location_on, size: 20, color: Colors.blue[700]),
                label: Text(
                  "$distance km away",
                  style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
                ),
              ),

            SizedBox(height: 20),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verification Status
                    if (isVerified)
                      Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.verified_user, color: Colors.blue),
                              SizedBox(width: 12),
                              Text(
                                "Verified Professional",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 24),
                        ],
                      ),

                    _buildInfoRow(Icons.work, "Experience", experience),
                    Divider(height: 24),
                    _buildInfoRow(Icons.category, "Specialization", partnerType),

                    SizedBox(height: 16),
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
              } : () {
                // Book for later functionality
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Added $name to your future bookings"))
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: available ? Colors.blue[300] : Colors.blue[300],
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                available ? "Book Plumber" : "Book for Later",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Colors.blue[700]),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}