import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class ExplorePage extends StatefulWidget {
  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late Stream<QuerySnapshot> _professionalsStream;
  bool isLoading = true;
  Map<String, dynamic>? currentUserData;
  List<Map<String, dynamic>> availableProfessionals = [];
  String searchQuery = "";

  // Offers list
  final List<String> offers = [
    "20% OFF on Home Cleaning!",
    "Flat ₹100 OFF on Carpentry",
    "Special Discount on First Booking!"
  ];

  // Color mapping for different service types
  final Map<String, Color> serviceColors = {
    'Electrician': Colors.orange[300]!,
    'Plumber': Colors.blue[300]!,
    'Carpenter': Colors.brown[400]!,
    'Painter': Colors.deepPurple[300]!,
    'Locksmith': Colors.green[300]!,
    'Home Installer': Colors.yellow[300]!,
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
    // Get all professionals initially
    _professionalsStream = FirebaseFirestore.instance
        .collection('users')
        .snapshots();
  }

  Future<void> _loadCurrentUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        String? phoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber;

        if (phoneNumber != null) {
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

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371;
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  void _filterProfessionals(List<QueryDocumentSnapshot> professionalDocs) {
    availableProfessionals.clear();

    if (currentUserData == null) return;

    double? customerLat, customerLng;

    if (currentUserData!.containsKey('residenceDetails') &&
        currentUserData!['residenceDetails'].containsKey('location')) {
      customerLat = currentUserData!['residenceDetails']['location']['latitude']?.toDouble();
      customerLng = currentUserData!['residenceDetails']['location']['longitude']?.toDouble();
    } else if (currentUserData!.containsKey('locationDetails')) {
      customerLat = currentUserData!['locationDetails']['latitude']?.toDouble();
      customerLng = currentUserData!['locationDetails']['longitude']?.toDouble();
    }

    if (customerLat == null || customerLng == null) return;

    for (var doc in professionalDocs) {
      var data = doc.data() as Map<String, dynamic>;
      if (!(data['isAvailable'] ?? false)) continue;

      double professionalLat = 0.0;
      double professionalLng = 0.0;
      double serviceRadiusKm = 0.5;

      if (data.containsKey('locationDetails')) {
        professionalLat = data['locationDetails']['latitude']?.toDouble() ?? 0.0;
        professionalLng = data['locationDetails']['longitude']?.toDouble() ?? 0.0;
      }

      if (data.containsKey('serviceRadius') && data['serviceRadius'] != null) {
        String radiusStr = data['serviceRadius'] as String;
        if (radiusStr.contains("0.5")) {
          serviceRadiusKm = 0.5;
        } else if (radiusStr.contains("1")) {
          serviceRadiusKm = 1.0;
        } else if (radiusStr.contains("2")) {
          serviceRadiusKm = 2.0;
        } else if (radiusStr.contains("5")) {
          serviceRadiusKm = 5.0;
        }
      }

      double distance = calculateDistance(
          customerLat, customerLng, professionalLat, professionalLng);

      if (distance <= serviceRadiusKm) {
        data['distance'] = distance.toStringAsFixed(1);
        availableProfessionals.add(data);
      }
    }

    // Sort by service type and then by distance
    availableProfessionals.sort((a, b) {
      int typeComparison = (a['partnerType'] ?? '').compareTo(b['partnerType'] ?? '');
      if (typeComparison != 0) return typeComparison;

      double distA = double.tryParse(a['distance'] ?? '0.0') ?? 0.0;
      double distB = double.tryParse(b['distance'] ?? '0.0') ?? 0.0;
      return distA.compareTo(distB);
    });
  }

  // Search Bar Widget
  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        onChanged: (value) => setState(() => searchQuery = value),
        decoration: InputDecoration(
          hintText: "Search professionals or services...",
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // Offers Section Widget
  Widget _buildOffersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            "Offers For You",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          height: 100,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: offers.length,
            itemBuilder: (context, index) {
              return Container(
                width: 200,
                margin: EdgeInsets.only(right: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[700],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    offers[index],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Explore Services",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Color(0xFFFFFFC4), // Light yellow background
        centerTitle: true,
        elevation: 4,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          _buildSearchBar(),

          // Offers Section
          _buildOffersSection(),

          // Featured Professionals Title
          Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              "Featured Professionals",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Professionals Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _professionalsStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No professionals found'));
                }

                _filterProfessionals(snapshot.data!.docs);

                // Filter by search query
                final filteredProfessionals = availableProfessionals.where((professional) {
                  final name = professional['name']?.toString().toLowerCase() ?? '';
                  final service = professional['partnerType']?.toString().toLowerCase() ?? '';
                  final query = searchQuery.toLowerCase();
                  return name.contains(query) || service.contains(query);
                }).toList();

                if (filteredProfessionals.isEmpty) {
                  return Center(child: Text('No matching professionals found'));
                }

                return GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: filteredProfessionals.length,
                  itemBuilder: (context, index) {
                    return _buildProfessionalTile(filteredProfessionals[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalTile(Map<String, dynamic> professional) {
    final serviceType = professional['partnerType'] ?? 'Professional';
    final color = serviceColors[serviceType] ?? Colors.grey[300]!;
    final isVerified = professional['verificationStatus'] == "verified";
    final distance = professional['distance'] ?? "Unknown";
    final available = professional['isAvailable'] ?? false;

    return GestureDetector(
      onTap: () => _navigateToProfessionalDetails(professional),
      child: Stack(
        children: [
          // Main card container
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            height: double.infinity, // Take full height of grid cell
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image area with fixed height
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.asset(
                        'assets/images/service_${serviceType.toLowerCase()}.jpg',
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 100,
                          color: color.withOpacity(0.3),
                          child: Center(child: Icon(Icons.person, size: 50, color: color)),
                        ),
                      ),
                    ),
                    if (isVerified)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.verified, size: 20, color: Colors.blue),
                        ),
                      ),
                  ],
                ),

                // Professional details
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        professional['name'] ?? 'Unknown',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),

                      // Service type and distance
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              serviceType,
                              style: TextStyle(
                                fontSize: 12,
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Spacer(),
                          Icon(Icons.location_on, size: 14, color: Colors.grey),
                          SizedBox(width: 2),
                          Text(
                            '$distance km',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),

                      // Rating (reduced vertical space)
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            professional['rating']?.toStringAsFixed(1) ?? '0.0',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Availability indicator outside the card (at bottom)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: available ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(12),
                  topLeft: Radius.circular(12),
                ),
              ),
              child: Text(
                available ? 'Available' : 'Unavailable',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToProfessionalDetails(Map<String, dynamic> professional) {
    final name = professional['name'] ?? 'Unknown';
    final imageUrl = professional['profileImage'] ?? "assets/images/profile image.png";
    final isVerified = professional['verificationStatus'] == "verified";
    final rating = professional['rating']?.toStringAsFixed(1) ?? '0.0';
    final distance = professional['distance'] ?? "Unknown";
    final experience = professional['experience'] ?? 'Not specified';
    final partnerType = professional['partnerType'] ?? 'Professional';
    final available = professional['isAvailable'] ?? false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text("$partnerType Details"),
            backgroundColor: serviceColors[partnerType] ?? Colors.blue,
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
                    Text(rating,
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
                    backgroundColor: available
                        ? (serviceColors[partnerType] ?? Colors.blue)
                        : Colors.grey,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    available ? "Book $partnerType" : "Book for Later",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 30, color: Colors.grey[600]),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 14, color: Colors.grey)),
            Text(value,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }
}