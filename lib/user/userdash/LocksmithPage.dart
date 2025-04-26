import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class LocksmithPage extends StatefulWidget {
  @override
  _LocksmithPageState createState() => _LocksmithPageState();
}

class _LocksmithPageState extends State<LocksmithPage> {
  late Stream<QuerySnapshot> _locksmithsStream;
  bool isLoading = true;
  Map<String, dynamic>? currentUserData;
  List<Map<String, dynamic>> availableInRangeLocksmiths = [];
  List<Map<String, dynamic>> unavailableInRangeLocksmiths = [];
  List<Map<String, dynamic>> outOfRangeLocksmiths = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
    // Get all locksmiths initially
    _locksmithsStream = FirebaseFirestore.instance
        .collection('users')
        .where('partnerType', isEqualTo: 'Locksmith')
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

  void _filterLocksmiths(List<QueryDocumentSnapshot> locksmithDocs) {
    availableInRangeLocksmiths.clear();
    unavailableInRangeLocksmiths.clear();
    outOfRangeLocksmiths.clear();

    if (currentUserData == null) {
      // If no user data, put all in out of range
      for (var doc in locksmithDocs) {
        var data = doc.data() as Map<String, dynamic>;
        outOfRangeLocksmiths.add(data);
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
      for (var doc in locksmithDocs) {
        var data = doc.data() as Map<String, dynamic>;
        bool isAvailable = data['isAvailable'] ?? false;

        if (isAvailable) {
          availableInRangeLocksmiths.add(data);
        } else {
          unavailableInRangeLocksmiths.add(data);
        }
      }
      return;
    }

    // Filter locksmiths based on location and availability
    for (var doc in locksmithDocs) {
      var data = doc.data() as Map<String, dynamic>;
      bool isAvailable = data['isAvailable'] ?? false;
      double locksmithLat = 0.0;
      double locksmithLng = 0.0;
      double serviceRadiusKm = 0.5; // Default smaller value, was 5.0 before

      // Extract location data
      if (data.containsKey('locationDetails')) {
        locksmithLat = data['locationDetails']['latitude']?.toDouble() ?? 0.0;
        locksmithLng = data['locationDetails']['longitude']?.toDouble() ?? 0.0;
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
          locksmithLat,
          locksmithLng
      );

      // Add debug printing
      print('Locksmith: ${data['name']}');
      print('Customer: $customerLat, $customerLng');
      print('Locksmith: $locksmithLat, $locksmithLng');
      print('Calculated distance: $distance km');
      print('Service radius: $serviceRadiusKm km');
      print('Within radius: ${distance <= serviceRadiusKm}');

      // Add calculated distance to locksmith data
      data['distance'] = distance.toStringAsFixed(1);

      // Check if customer is within service radius
      bool isWithinRadius = distance <= serviceRadiusKm;

      // Categorize locksmiths into three groups
      if (isWithinRadius) {
        if (isAvailable) {
          availableInRangeLocksmiths.add(data);
        } else {
          unavailableInRangeLocksmiths.add(data);
        }
      } else {
        outOfRangeLocksmiths.add(data);
      }
    }

    // Sort all lists by distance
    availableInRangeLocksmiths.sort((a, b) {
      double distA = double.tryParse(a['distance'] ?? '0.0') ?? 0.0;
      double distB = double.tryParse(b['distance'] ?? '0.0') ?? 0.0;
      return distA.compareTo(distB);
    });

    unavailableInRangeLocksmiths.sort((a, b) {
      double distA = double.tryParse(a['distance'] ?? '0.0') ?? 0.0;
      double distB = double.tryParse(b['distance'] ?? '0.0') ?? 0.0;
      return distA.compareTo(distB);
    });

    outOfRangeLocksmiths.sort((a, b) {
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
        title: Text("Locksmiths",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.green[300], // Green color scheme for locksmiths
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
        stream: _locksmithsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No locksmiths found'));
          }

          // Filter locksmiths based on location
          _filterLocksmiths(snapshot.data!.docs);

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
                        Icon(Icons.location_on, color: Colors.green[300]),
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

                // Available In Range Locksmiths Section
                Text(
                  "Available (In Range) - ${availableInRangeLocksmiths.length}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                SizedBox(height: 12),
                availableInRangeLocksmiths.isEmpty
                    ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text("No available locksmiths in your area"),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: availableInRangeLocksmiths.length,
                  itemBuilder: (context, index) {
                    return _buildLocksmithListItem(
                      availableInRangeLocksmiths[index],
                      status: "Available",
                    );
                  },
                ),

                SizedBox(height: 24),

                // Unavailable In Range Locksmiths Section
                Text(
                  "Unavailable (In Range) - ${unavailableInRangeLocksmiths.length}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                SizedBox(height: 12),
                unavailableInRangeLocksmiths.isEmpty
                    ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text("No unavailable locksmiths in your area"),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: unavailableInRangeLocksmiths.length,
                  itemBuilder: (context, index) {
                    return _buildLocksmithListItem(
                      unavailableInRangeLocksmiths[index],
                      status: "Unavailable",
                    );
                  },
                ),

                SizedBox(height: 24),

                // Out of Range Locksmiths Section
                Text(
                  "Out of Range - ${outOfRangeLocksmiths.length}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 12),
                outOfRangeLocksmiths.isEmpty
                    ? Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text("No locksmiths out of range"),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: outOfRangeLocksmiths.length,
                  itemBuilder: (context, index) {
                    return _buildLocksmithListItem(
                      outOfRangeLocksmiths[index],
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

  Widget _buildLocksmithListItem(Map<String, dynamic> locksmith,
      {required String status}) {
    // Extract data with defaults
    String name = locksmith["name"] ?? "Unknown";
    String experience = locksmith["experience"] ?? "Not specified";
    String imageUrl = locksmith["profileImage"] ??
        "assets/images/profile image.png";
    String distance = locksmith["distance"] ?? "Unknown";
    bool isVerified = locksmith["verificationStatus"] == "verified";
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
                    LocksmithDetailsPage(locksmith: locksmith),
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
                              color: Colors.green[300],
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
                                          color: Colors.green[300]),
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
                                  // Book this locksmith
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(
                                          "Booking request sent to $name"))
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[300],
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
                                  backgroundColor: Colors.green[200],
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
                                    color: Colors.green[700]),
                                SizedBox(width: 4),
                                Text(
                                  "$distance km away",
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.green[700]),
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
                      Icon(Icons.verified_user, size: 14, color: Colors.green[300]),
                      SizedBox(width: 4),
                      Text(
                        "Verified Professional",
                        style: TextStyle(fontSize: 12, color: Colors.green[300]),
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

class LocksmithDetailsPage extends StatelessWidget {
  final Map<String, dynamic> locksmith;

  LocksmithDetailsPage({required this.locksmith});

  @override
  Widget build(BuildContext context) {
    // Extract values with null safety
    String name = locksmith["name"] ?? "Unknown";
    String partnerType = locksmith["partnerType"] ?? "Locksmith";
    bool available = locksmith["isAvailable"] ?? false;
    bool isVerified = locksmith["verificationStatus"] == "verified";
    String verificationDate = locksmith["verificationDate"] ?? "";

    // Store the actual rating value
    double? ratingValue = locksmith["rating"]?.toDouble();

    // Display text for rating - either the actual value or "no ratings available"
    String ratingDisplay = ratingValue != null ? ratingValue.toString() : "no ratings available";

    String imageUrl = locksmith["profileImage"] ?? "assets/images/profile image.png";
    String distance = locksmith["distance"] ?? "Unknown";
    String experience = locksmith["experience"] ?? "Not specified";

    return Scaffold(
      appBar: AppBar(
        title: Text("Locksmith Details"),
        backgroundColor: Colors.green[300],
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
                      color: Colors.green[300],
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
                if (isVerified) Icon(Icons.verified, size: 24, color: Colors.green[300]),
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
                backgroundColor: Colors.green[100],
                avatar: Icon(Icons.location_on, size: 20, color: Colors.green[700]),
                label: Text(
                  "$distance km away",
                  style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
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
                              Icon(Icons.verified_user, color: Colors.green[300]),
                              SizedBox(width: 12),
                              Text(
                                "Verified Professional",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[300],
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
                backgroundColor: available ? Colors.green[300] : Colors.green[200],
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                available ? "Book Locksmith" : "Book for Later",
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
        Icon(icon, size: 22, color: Colors.green[700]),
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