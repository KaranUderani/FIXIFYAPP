/*import 'package:flutter/material.dart';
import 'package:fixifypartner/partner/dash/screens/paymentsscreen.dart';
import 'package:fixifypartner/partner/personalization/screens/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:fixifypartner/partner/dash/screens/booking_popup.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool availabilityToggle = false;
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? currentHotspot;
  String? currentState;
  String? currentCity;
  TimeOfDay? availabilityEndTime;
  DateTime? availabilityEndDateTime;
  bool isLoading = true;
  Timer? _availabilityTimer;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      _buildDashboardBody(),
      PaymentHistoryScreen(),
      ProfileScreen(),
    ];

    _fetchUserData();
  }

  Widget _buildDashboardBody() {
    return DashboardScreenBody(
      currentHotspot: currentHotspot,
      availabilityToggle: availabilityToggle,
      availabilityEndTime: availabilityToggle ? availabilityEndTime : null,
      onHotspotTap: _showHotspotChangeDialog,
      onAvailabilityChanged: _handleAvailabilityToggle,
      onTimeChange: _handleTimeChange,
      isLoading: isLoading,
    );
  }

  @override
  void dispose() {
    _availabilityTimer?.cancel();
    super.dispose();
  }

  void _setupAvailabilityTimer(DateTime endDateTime) {
    _availabilityTimer?.cancel();
    final now = DateTime.now();
    final duration = endDateTime.isAfter(now) ? endDateTime.difference(now) : Duration.zero;

    if (duration > Duration.zero) {
      _availabilityTimer = Timer(duration, _handleAvailabilityExpiration);
    } else {
      _handleAvailabilityExpiration();
    }
  }

  void _handleAvailabilityExpiration() {
    if (mounted) {
      setState(() {
        availabilityToggle = false;
        availabilityEndTime = null;
        availabilityEndDateTime = null;
        _screens[0] = _buildDashboardBody();
      });
      _updateAvailabilityStatus(false);
      _showSnackbar("Your availability period has ended");
    }
  }

  Future<void> _handleTimeChange() async {
    final time = await _selectAvailabilityEndTime();
    if (time != null && mounted) {
      setState(() {
        availabilityEndTime = time;
        _screens[0] = _buildDashboardBody();
      });
      await _updateAvailabilityStatus(true, endTime: time);
    }
  }
  Future<void> _handleAvailabilityToggle(bool value) async {
    // If toggling ON, prompt for time selection
    if (value) {
      final time = await _selectAvailabilityEndTime();
      if (time != null) {
        setState(() {
          availabilityToggle = true;
          availabilityEndTime = time;
          _screens[0] = _buildDashboardBody();
        });
        await _updateAvailabilityStatus(true, endTime: time);
      } else {
        // User cancelled time selection - don't turn on toggle
        setState(() {
          availabilityToggle = false;
          _screens[0] = _buildDashboardBody();
        });
      }
    }
    // If toggling OFF, simply update the state
    else {
      setState(() {
        availabilityToggle = false;
        availabilityEndTime = null;
        _screens[0] = _buildDashboardBody();
      });
      await _updateAvailabilityStatus(false);
    }
  }

  Future<TimeOfDay?> _selectAvailabilityEndTime() async {
    // Use the current availabilityEndTime if it exists
    // Otherwise, use the current time plus 1 hour (as a reasonable default)
    final now = TimeOfDay.now();
    final TimeOfDay initialTime = TimeOfDay(
        hour: (now.hour) % 24,  // Ensure hour is within 0-23
        minute: ((now.minute + 2.5) ~/ 5 * 5) % 60  // Round to nearest 5 minutes
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFFCCAA00),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    return picked;
  }

  Future<void> _fetchUserData() async {
    setState(() {
      isLoading = true;
      _screens[0] = _buildDashboardBody();
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String phoneNumber = currentUser.phoneNumber ?? '';

        if (phoneNumber.isEmpty) {
          QuerySnapshot userDocs = await _firestore.collection('users')
              .where('uid', isEqualTo: currentUser.uid).get();
          if (userDocs.docs.isNotEmpty) {
            phoneNumber = userDocs.docs.first.id;
          }
        }

        if (phoneNumber.isNotEmpty) {
          DocumentSnapshot userDoc = await _firestore.collection('users').doc(phoneNumber).get();

          if (userDoc.exists) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            bool isAvailable = userData['isAvailable'] ?? false;
            DateTime? endDateTime;

            if (userData['availabilityEndTime'] != null) {
              Timestamp timestamp = userData['availabilityEndTime'];
              endDateTime = timestamp.toDate();

              if (endDateTime.isBefore(DateTime.now())) {
                isAvailable = false;
                await _updateAvailabilityStatus(false);
                endDateTime = null;
              } else {
                _setupAvailabilityTimer(endDateTime);
              }
            }

            setState(() {
              availabilityToggle = isAvailable;
              availabilityEndTime = endDateTime != null
                  ? TimeOfDay(hour: endDateTime.hour, minute: endDateTime.minute)
                  : null;
              availabilityEndDateTime = endDateTime;

              if (userData['locationDetails'] != null) {
                Map<String, dynamic> locationDetails = userData['locationDetails'];
                currentHotspot = locationDetails['hotspot'];
                currentState = locationDetails['state'];
                currentCity = locationDetails['city'];
              }

              isLoading = false;
              _screens[0] = _buildDashboardBody();
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        _screens[0] = _buildDashboardBody();
      });
      _showSnackbar("Error fetching user data: $e");
    }
  }

  Future<void> _updateAvailabilityStatus(bool isAvailable, {TimeOfDay? endTime}) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String phoneNumber = currentUser.phoneNumber ?? '';

        if (phoneNumber.isEmpty) {
          QuerySnapshot userDocs = await _firestore.collection('users')
              .where('uid', isEqualTo: currentUser.uid).get();
          if (userDocs.docs.isNotEmpty) {
            phoneNumber = userDocs.docs.first.id;
          }
        }

        if (phoneNumber.isNotEmpty) {
          await _firestore.runTransaction((transaction) async {
            DocumentReference docRef = _firestore.collection('users').doc(phoneNumber);
            Map<String, dynamic> updateData = {'isAvailable': isAvailable};

            if (endTime != null) {
              DateTime now = DateTime.now();
              DateTime endDateTime = DateTime(
                  now.year, now.month, now.day, endTime.hour, endTime.minute);

              if (endDateTime.isBefore(now)) {
                endDateTime = endDateTime.add(Duration(days: 1));
              }

              updateData['availabilityEndTime'] = Timestamp.fromDate(endDateTime);
              _setupAvailabilityTimer(endDateTime);
            } else if (!isAvailable) {
              updateData['availabilityEndTime'] = FieldValue.delete();
              _availabilityTimer?.cancel();
            }

            transaction.update(docRef, updateData);
          });

          _showSnackbar(isAvailable
              ? "You are now available for bookings"
              : "You are now unavailable for bookings");
        }
      }
    } catch (e) {
      _showSnackbar("Error updating availability status: $e");
      throw e;
    }
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  Future<void> _showHotspotChangeDialog() async {
    // Enhanced Location Data
    Map<String, Map<String, dynamic>> enhancedLocations = {
      'Maharashtra': {
        'cities': ['Mumbai', 'Pune', 'Nagpur'],
        'hotspots': {
          'Mumbai': ['Bandra', 'Juhu', 'Andheri', 'Colaba'],
          'Pune': ['Koregaon Park', 'Baner', 'Wakad', 'Hinjewadi'],
          'Nagpur': ['Sitabuldi', 'Dharampeth', 'Sadar']
        }
      },
      'Gujarat': {
        'cities': ['Ahmedabad', 'Surat'],
        'hotspots': {
          'Ahmedabad': ['Satellite', 'Vastrapur', 'Bodakdev', 'CG Road'],
          'Surat': ['Adajan', 'VIP Road', 'Vesu', 'Majura Gate']
        }
      },
      'Delhi': {
        'cities': ['New Delhi'],
        'hotspots': {
          'New Delhi': ['Connaught Place', 'Hauz Khas', 'Nehru Place', 'Saket']
        }
      }
    };

    List<String> states = enhancedLocations.keys.toList();
    String? selectedState = currentState;
    String? selectedCity = currentCity;
    String? selectedHotspot = currentHotspot;
    List<String> radiusOptions = ['Up to 0.5 km', 'Up to 1 km'];
    String? selectedRadius = await _getServiceRadius(_auth.currentUser?.phoneNumber ?? '');

    List<String> getCities(String state) {
      return (enhancedLocations[state]!['cities'] as List<dynamic>).cast<String>();
    }

    List<String> getHotspots(String state, String city) {
      return (enhancedLocations[state]!['hotspots'][city] as List<dynamic>).cast<String>();
    }

    bool isOtpSent = false;
    bool isOtpVerified = false;
    String? verificationId;
    final TextEditingController otpController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Change Hotspot Location"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedState,
                      decoration: InputDecoration(
                        labelText: "State",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: states.map((state) {
                        return DropdownMenuItem<String>(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedState = value;
                          selectedCity = null;
                          selectedHotspot = null;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCity,
                      decoration: InputDecoration(
                        labelText: "City",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: selectedState != null
                          ? getCities(selectedState!).map((city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        );
                      }).toList()
                          : [],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCity = value;
                          selectedHotspot = null;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedHotspot,
                      decoration: InputDecoration(
                        labelText: "Hotspot",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: (selectedState != null && selectedCity != null)
                          ? getHotspots(selectedState!, selectedCity!).map((hotspot) {
                        return DropdownMenuItem<String>(
                          value: hotspot,
                          child: Text(hotspot),
                        );
                      }).toList()
                          : [],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedHotspot = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRadius,
                      decoration: InputDecoration(
                        labelText: "Service Radius",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: radiusOptions.map((radius) {
                        return DropdownMenuItem<String>(
                          value: radius,
                          child: Text(radius),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedRadius = value;
                        });
                      },
                    ),
                    SizedBox(height: 24),
                    if (!isOtpSent)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (selectedState != null &&
                              selectedCity != null &&
                              selectedHotspot != null &&
                              selectedRadius != null)
                              ? () async {
                            try {
                              User? currentUser = _auth.currentUser;
                              if (currentUser != null) {
                                String phoneNumber = currentUser.phoneNumber ?? '';
                                if (phoneNumber.isEmpty) {
                                  QuerySnapshot userDocs = await _firestore
                                      .collection('users')
                                      .where('uid', isEqualTo: currentUser.uid)
                                      .get();
                                  if (userDocs.docs.isNotEmpty) {
                                    phoneNumber = userDocs.docs.first.id;
                                  }
                                }

                                if (phoneNumber.isNotEmpty) {
                                  await _auth.verifyPhoneNumber(
                                    phoneNumber: phoneNumber,
                                    verificationCompleted: (PhoneAuthCredential credential) async {},
                                    verificationFailed: (FirebaseAuthException e) {
                                      _showSnackbar("Verification Failed: ${e.message}");
                                    },
                                    codeSent: (String verId, int? resendToken) {
                                      setDialogState(() {
                                        verificationId = verId;
                                        isOtpSent = true;
                                      });
                                    },
                                    codeAutoRetrievalTimeout: (String verId) {},
                                  );
                                }
                              }
                            } catch (e) {
                              _showSnackbar("Error sending OTP: $e");
                            }
                          }
                              : null,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text("Verify With OTP"),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFCCAA00),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    if (isOtpSent && !isOtpVerified)
                      Column(
                        children: [
                          Text(
                            "Enter the OTP sent to your registered mobile number",
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          Pinput(
                            controller: otpController,
                            length: 6,
                            defaultPinTheme: PinTheme(
                              width: 50,
                              height: 50,
                              textStyle: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  if (verificationId != null && otpController.text.trim().isNotEmpty) {
                                    PhoneAuthCredential credential = PhoneAuthProvider.credential(
                                      verificationId: verificationId!,
                                      smsCode: otpController.text.trim(),
                                    );

                                    await _auth.signInWithCredential(credential);
                                    setDialogState(() {
                                      isOtpVerified = true;
                                    });

                                    if (selectedState != null &&
                                        selectedCity != null &&
                                        selectedHotspot != null &&
                                        selectedRadius != null) {
                                      await _updateHotspot(
                                          selectedState!,
                                          selectedCity!,
                                          selectedHotspot!,
                                          selectedRadius!
                                      );
                                      Navigator.pop(context);
                                      _showSnackbar("Hotspot updated successfully!");
                                    }
                                  }
                                } catch (e) {
                                  _showSnackbar("OTP Verification Failed: $e");
                                }
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text("Verify OTP"),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFCCAA00),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Cancel"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black54,
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateHotspot(String state, String city, String hotspot, String radius) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String phoneNumber = currentUser.phoneNumber ?? '';

        if (phoneNumber.isEmpty) {
          QuerySnapshot userDocs = await _firestore.collection('users')
              .where('uid', isEqualTo: currentUser.uid).get();
          if (userDocs.docs.isNotEmpty) {
            phoneNumber = userDocs.docs.first.id;
          }
        }

        if (phoneNumber.isNotEmpty) {
          // Get the current location details including lat/long
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            _showSnackbar('Please enable location services');
            return;
          }

          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.denied) {
              _showSnackbar('Location permissions are denied');
              return;
            }
          }

          if (permission == LocationPermission.deniedForever) {
            _showSnackbar('Location permissions are permanently denied');
            return;
          }

          // Get current position
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          await _firestore.collection('users').doc(phoneNumber).update({
            'locationDetails': {
              'state': state,
              'city': city,
              'hotspot': hotspot,
              'serviceRadius': radius,
              'latitude': position.latitude,
              'longitude': position.longitude,
              'geoPoint': GeoPoint(position.latitude, position.longitude),
            }
          });

          setState(() {
            currentState = state;
            currentCity = city;
            currentHotspot = hotspot;
            _screens[0] = _buildDashboardBody();
          });
        }
      }
    } catch (e) {
      _showSnackbar("Error updating hotspot: $e");
      rethrow;
    }
  }

  Future<String> _getServiceRadius(String phoneNumber) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(phoneNumber).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData['locationDetails'] != null) {
          return userData['locationDetails']['serviceRadius'] ?? 'Up to 1 km';
        }
      }
      return 'Up to 1 km';
    } catch (e) {
      return 'Up to 1 km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFDE7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFCCAA00),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/imagefixify.png', height: 32),
            SizedBox(width: 8),
            Text(
              'FIXIFY',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Color(0xFFCCAA00),
            unselectedItemColor: Colors.grey.shade600,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 10,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.payment_outlined),
                activeIcon: Icon(Icons.payment),
                label: 'Payments',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardScreenBody extends StatelessWidget {
  final String? currentHotspot;
  final bool availabilityToggle;
  final TimeOfDay? availabilityEndTime;
  final VoidCallback onHotspotTap;
  final Function(bool) onAvailabilityChanged;
  final VoidCallback onTimeChange; // This stays as VoidCallback
  final bool isLoading;

  const DashboardScreenBody({
    Key? key,
    this.currentHotspot,
    required this.availabilityToggle,
    this.availabilityEndTime,
    required this.onHotspotTap,
    required this.onAvailabilityChanged,
    required this.onTimeChange,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Color(0xFFCCAA00),
          strokeWidth: 2,
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Location Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_pin, color: Color(0xFFCCAA00), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'SERVICE LOCATION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  GestureDetector(
                    onTap: onHotspotTap,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: Color(0xFFCCAA00), size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentHotspot != null
                                  ? currentHotspot!
                                  : 'Select your hotspot',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.grey.shade500),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Availability Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Color(0xFFCCAA00), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'AVAILABILITY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set Your Availability',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (availabilityToggle && availabilityEndTime != null)
                            Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Until ${availabilityEndTime!.format(context)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Transform.scale(
                        scale: 0.9,
                        child: Switch.adaptive(
                          value: availabilityToggle,
                          onChanged: onAvailabilityChanged,
                          activeColor: Colors.white,
                          activeTrackColor: Color(0xFFCCAA00),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  if (availabilityToggle)
                    Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: onTimeChange,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Change Availability Time',
                            style: TextStyle(
                              color: Color(0xFFCCAA00),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Status Indicator
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: availabilityToggle
                  ? Color(0xFFE8F5E9)
                  : Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: availabilityToggle
                    ? Color(0xFF81C784)
                    : Color(0xFFEF9A9A),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  availabilityToggle ? Icons.check_circle : Icons.error,
                  color: availabilityToggle
                      ? Color(0xFF2E7D32)
                      : Color(0xFFC62828),
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    availabilityToggle
                        ? "You're currently available for bookings"
                        : "You're currently unavailable for bookings",
                    style: TextStyle(
                      color: availabilityToggle
                          ? Color(0xFF2E7D32)
                          : Color(0xFFC62828),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Upcoming Bookings Section
          Text(
            'UPCOMING BOOKINGS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/6902611.png',
                  height: 50,
                  width: 50,
                ),
                SizedBox(height: 16),
                Text(
                  'No upcoming bookings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'When you have bookings, they will appear here',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}*/import 'package:flutter/material.dart';
import 'package:fixifypartner/partner/dash/screens/paymentsscreen.dart';
import 'package:fixifypartner/partner/personalization/screens/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pinput/pinput.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:fixifypartner/partner/dash/screens/tracker_screen.dart'; // Adjust path as needed

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool availabilityToggle = false;
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? currentHotspot;
  String? currentState;
  String? currentCity;
  TimeOfDay? availabilityEndTime;
  DateTime? availabilityEndDateTime;
  bool isLoading = true;
  Timer? _availabilityTimer;
  Stream<QuerySnapshot>? _bookingStream;
  bool _isProcessingBooking = false;
  Timer? _bookingCheckTimer;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      _buildDashboardBody(),
      PaymentHistoryScreen(),
      ProfileScreen(),
    ];

    _fetchUserData();
    _setupBookingListener();

    // Check for scheduled bookings every minute
    _bookingCheckTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      _checkScheduledBookings();
    });
  }

  Widget _buildDashboardBody() {
    return DashboardScreenBody(
      currentHotspot: currentHotspot,
      availabilityToggle: availabilityToggle,
      availabilityEndTime: availabilityToggle ? availabilityEndTime : null,
      onHotspotTap: _showHotspotChangeDialog,
      onAvailabilityChanged: _handleAvailabilityToggle,
      onTimeChange: _handleTimeChange,
      isLoading: isLoading,
      firestore: _firestore,
      auth: _auth,
    );
  }

  void _setupBookingListener() {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      String phoneNumber = currentUser.phoneNumber ?? '';

      // Listen for bookings where providerPhone matches and status is pending
      _bookingStream = _firestore.collection('bookings')
          .where('providerPhone', isEqualTo: phoneNumber)
          .where('status', isEqualTo: 'pending')
          .snapshots();
    }
  }

  void _handleBookingResponse(String bookingId, bool isAccepted) async {
    if (_isProcessingBooking) return;
    _isProcessingBooking = true;

    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': isAccepted ? 'accepted' : 'rejected',
        'responseTime': FieldValue.serverTimestamp(),
      });

      if (isAccepted) {
        // Get the booking details
        DocumentSnapshot bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
        Map<String, dynamic> bookingData = bookingDoc.data() as Map<String, dynamic>;

        // Check if it's a "now" booking
        if (bookingData['bookingType'] == 'now') {
          // Navigate to tracker screen after a short delay to allow dialog to close
          Future.delayed(Duration(milliseconds: 300), () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrackerScreen(bookingId: bookingId),
              ),
            );
          });
        }
      }
    } catch (e) {
      _showSnackbar("Error processing booking: $e");
    } finally {
      _isProcessingBooking = false;
    }
  }

  void _navigateToServiceScreen(String bookingId) {
    // Replace with your actual service screen navigation
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('Service in Progress')),
          body: Center(child: Text('Service details for booking $bookingId')),
        ),
      ),
    );
  }

  void _checkScheduledBookings() async {
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      String phoneNumber = currentUser.phoneNumber ?? '';

      // Get accepted bookings where scheduled time has arrived
      QuerySnapshot snapshot = await _firestore.collection('bookings')
          .where('providerPhone', isEqualTo: phoneNumber)
          .where('status', isEqualTo: 'accepted')
          .get();

      DateTime now = DateTime.now();

      for (var doc in snapshot.docs) {
        Map<String, dynamic> bookingData = doc.data() as Map<String, dynamic>;

        if (bookingData['scheduleDate'] != null) {
          Timestamp scheduleTimestamp = bookingData['scheduleDate'];
          DateTime scheduleTime = scheduleTimestamp.toDate();

          // If the scheduled time is within the next 5 minutes
          if (scheduleTime.isBefore(now.add(Duration(minutes: 5))) ){
          _navigateToServiceScreen(doc.id);
          break;
          }
          }
          }
          }
          }

  String _formatScheduleDate(dynamic dateField) {
    if (dateField == null) return 'Immediate';
    if (dateField is Timestamp) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateField.toDate());
    }
    return dateField.toString();
  }

  @override
  void dispose() {
    _availabilityTimer?.cancel();
    _bookingCheckTimer?.cancel();
    super.dispose();
  }

  void _setupAvailabilityTimer(DateTime endDateTime) {
    _availabilityTimer?.cancel();
    final now = DateTime.now();
    final duration = endDateTime.isAfter(now) ? endDateTime.difference(now) : Duration.zero;

    if (duration > Duration.zero) {
      _availabilityTimer = Timer(duration, _handleAvailabilityExpiration);
    } else {
      _handleAvailabilityExpiration();
    }
  }

  void _handleAvailabilityExpiration() {
    if (mounted) {
      setState(() {
        availabilityToggle = false;
        availabilityEndTime = null;
        availabilityEndDateTime = null;
        _screens[0] = _buildDashboardBody();
      });
      _updateAvailabilityStatus(false);
      _showSnackbar("Your availability period has ended");
    }
  }

  Future<void> _handleTimeChange() async {
    final time = await _selectAvailabilityEndTime();
    if (time != null && mounted) {
      setState(() {
        availabilityEndTime = time;
        _screens[0] = _buildDashboardBody();
      });
      await _updateAvailabilityStatus(true, endTime: time);
    }
  }

  Future<void> _handleAvailabilityToggle(bool value) async {
    if (value) {
      final time = await _selectAvailabilityEndTime();
      if (time != null) {
        setState(() {
          availabilityToggle = true;
          availabilityEndTime = time;
          _screens[0] = _buildDashboardBody();
        });
        await _updateAvailabilityStatus(true, endTime: time);
      } else {
        setState(() {
          availabilityToggle = false;
          _screens[0] = _buildDashboardBody();
        });
      }
    } else {
      setState(() {
        availabilityToggle = false;
        availabilityEndTime = null;
        _screens[0] = _buildDashboardBody();
      });
      await _updateAvailabilityStatus(false);
    }
  }

  Future<TimeOfDay?> _selectAvailabilityEndTime() async {
    final now = TimeOfDay.now();
    final TimeOfDay initialTime = TimeOfDay(
        hour: (now.hour) % 24,
        minute: ((now.minute + 2.5) ~/ 5 * 5) % 60
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFFCCAA00),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    return picked;
  }

  Future<void> _fetchUserData() async {
    setState(() {
      isLoading = true;
      _screens[0] = _buildDashboardBody();
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String phoneNumber = currentUser.phoneNumber ?? '';

        if (phoneNumber.isEmpty) {
          QuerySnapshot userDocs = await _firestore.collection('users')
              .where('uid', isEqualTo: currentUser.uid).get();
          if (userDocs.docs.isNotEmpty) {
            phoneNumber = userDocs.docs.first.id;
          }
        }

        if (phoneNumber.isNotEmpty) {
          DocumentSnapshot userDoc = await _firestore.collection('users').doc(phoneNumber).get();

          if (userDoc.exists) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            bool isAvailable = userData['isAvailable'] ?? false;
            DateTime? endDateTime;

            if (userData['availabilityEndTime'] != null) {
              Timestamp timestamp = userData['availabilityEndTime'];
              endDateTime = timestamp.toDate();

              if (endDateTime.isBefore(DateTime.now())) {
                isAvailable = false;
                await _updateAvailabilityStatus(false);
                endDateTime = null;
              } else {
                _setupAvailabilityTimer(endDateTime);
              }
            }

            setState(() {
              availabilityToggle = isAvailable;
              availabilityEndTime = endDateTime != null
                  ? TimeOfDay(hour: endDateTime.hour, minute: endDateTime.minute)
                  : null;
              availabilityEndDateTime = endDateTime;

              if (userData['locationDetails'] != null) {
                Map<String, dynamic> locationDetails = userData['locationDetails'];
                currentHotspot = locationDetails['hotspot'];
                currentState = locationDetails['state'];
                currentCity = locationDetails['city'];
              }

              isLoading = false;
              _screens[0] = _buildDashboardBody();
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        _screens[0] = _buildDashboardBody();
      });
      _showSnackbar("Error fetching user data: $e");
    }
  }

  Future<void> _updateAvailabilityStatus(bool isAvailable, {TimeOfDay? endTime}) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String phoneNumber = currentUser.phoneNumber ?? '';

        if (phoneNumber.isEmpty) {
          QuerySnapshot userDocs = await _firestore.collection('users')
              .where('uid', isEqualTo: currentUser.uid).get();
          if (userDocs.docs.isNotEmpty) {
            phoneNumber = userDocs.docs.first.id;
          }
        }

        if (phoneNumber.isNotEmpty) {
          await _firestore.runTransaction((transaction) async {
            DocumentReference docRef = _firestore.collection('users').doc(phoneNumber);
            Map<String, dynamic> updateData = {'isAvailable': isAvailable};

            if (endTime != null) {
              DateTime now = DateTime.now();
              DateTime endDateTime = DateTime(
                  now.year, now.month, now.day, endTime.hour, endTime.minute);

              if (endDateTime.isBefore(now)) {
                endDateTime = endDateTime.add(Duration(days: 1));
              }

              updateData['availabilityEndTime'] = Timestamp.fromDate(endDateTime);
              _setupAvailabilityTimer(endDateTime);
            } else if (!isAvailable) {
              updateData['availabilityEndTime'] = FieldValue.delete();
              _availabilityTimer?.cancel();
            }

            transaction.update(docRef, updateData);
          });

          _showSnackbar(isAvailable
              ? "You are now available for bookings"
              : "You are now unavailable for bookings");
        }
      }
    } catch (e) {
      _showSnackbar("Error updating availability status: $e");
      throw e;
    }
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _showHotspotChangeDialog() async {
    Map<String, Map<String, dynamic>> enhancedLocations = {
      'Maharashtra': {
        'cities': ['Mumbai', 'Pune', 'Nagpur'],
        'hotspots': {
          'Mumbai': ['Bandra', 'Juhu', 'Andheri', 'Colaba'],
          'Pune': ['Koregaon Park', 'Baner', 'Wakad', 'Hinjewadi'],
          'Nagpur': ['Sitabuldi', 'Dharampeth', 'Sadar']
        }
      },
      'Gujarat': {
        'cities': ['Ahmedabad', 'Surat'],
        'hotspots': {
          'Ahmedabad': ['Satellite', 'Vastrapur', 'Bodakdev', 'CG Road'],
          'Surat': ['Adajan', 'VIP Road', 'Vesu', 'Majura Gate']
        }
      },
      'Delhi': {
        'cities': ['New Delhi'],
        'hotspots': {
          'New Delhi': ['Connaught Place', 'Hauz Khas', 'Nehru Place', 'Saket']
        }
      }
    };

    List<String> states = enhancedLocations.keys.toList();
    String? selectedState = currentState;
    String? selectedCity = currentCity;
    String? selectedHotspot = currentHotspot;
    List<String> radiusOptions = ['Up to 0.5 km', 'Up to 1 km'];
    String? selectedRadius = await _getServiceRadius(_auth.currentUser?.phoneNumber ?? '');

    List<String> getCities(String state) {
      return (enhancedLocations[state]!['cities'] as List<dynamic>).cast<String>();
    }

    List<String> getHotspots(String state, String city) {
      return (enhancedLocations[state]!['hotspots'][city] as List<dynamic>).cast<String>();
    }

    bool isOtpSent = false;
    bool isOtpVerified = false;
    String? verificationId;
    final TextEditingController otpController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Change Hotspot Location"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedState,
                      decoration: InputDecoration(
                        labelText: "State",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: states.map((state) {
                        return DropdownMenuItem<String>(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedState = value;
                          selectedCity = null;
                          selectedHotspot = null;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedCity,
                      decoration: InputDecoration(
                        labelText: "City",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: selectedState != null
                          ? getCities(selectedState!).map((city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        );
                      }).toList()
                          : [],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCity = value;
                          selectedHotspot = null;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedHotspot,
                      decoration: InputDecoration(
                        labelText: "Hotspot",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: (selectedState != null && selectedCity != null)
                          ? getHotspots(selectedState!, selectedCity!).map((hotspot) {
                        return DropdownMenuItem<String>(
                          value: hotspot,
                          child: Text(hotspot),
                        );
                      }).toList()
                          : [],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedHotspot = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRadius,
                      decoration: InputDecoration(
                        labelText: "Service Radius",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: radiusOptions.map((radius) {
                        return DropdownMenuItem<String>(
                          value: radius,
                          child: Text(radius),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedRadius = value;
                        });
                      },
                    ),
                    SizedBox(height: 24),
                    if (!isOtpSent)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (selectedState != null &&
                              selectedCity != null &&
                              selectedHotspot != null &&
                              selectedRadius != null)
                              ? () async {
                            try {
                              User? currentUser = _auth.currentUser;
                              if (currentUser != null) {
                                String phoneNumber = currentUser.phoneNumber ?? '';
                                if (phoneNumber.isEmpty) {
                                  QuerySnapshot userDocs = await _firestore
                                      .collection('users')
                                      .where('uid', isEqualTo: currentUser.uid)
                                      .get();
                                  if (userDocs.docs.isNotEmpty) {
                                    phoneNumber = userDocs.docs.first.id;
                                  }
                                }

                                if (phoneNumber.isNotEmpty) {
                                  await _auth.verifyPhoneNumber(
                                    phoneNumber: phoneNumber,
                                    verificationCompleted: (PhoneAuthCredential credential) async {},
                                    verificationFailed: (FirebaseAuthException e) {
                                      _showSnackbar("Verification Failed: ${e.message}");
                                    },
                                    codeSent: (String verId, int? resendToken) {
                                      setDialogState(() {
                                        verificationId = verId;
                                        isOtpSent = true;
                                      });
                                    },
                                    codeAutoRetrievalTimeout: (String verId) {},
                                  );
                                }
                              }
                            } catch (e) {
                              _showSnackbar("Error sending OTP: $e");
                            }
                          }
                              : null,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text("Verify With OTP"),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFCCAA00),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    if (isOtpSent && !isOtpVerified)
                      Column(
                        children: [
                          Text(
                            "Enter the OTP sent to your registered mobile number",
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          Pinput(
                            controller: otpController,
                            length: 6,
                            defaultPinTheme: PinTheme(
                              width: 50,
                              height: 50,
                              textStyle: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                try {
                                  if (verificationId != null && otpController.text.trim().isNotEmpty) {
                                    PhoneAuthCredential credential = PhoneAuthProvider.credential(
                                      verificationId: verificationId!,
                                      smsCode: otpController.text.trim(),
                                    );

                                    await _auth.signInWithCredential(credential);
                                    setDialogState(() {
                                      isOtpVerified = true;
                                    });

                                    if (selectedState != null &&
                                        selectedCity != null &&
                                        selectedHotspot != null &&
                                        selectedRadius != null) {
                                      await _updateHotspot(
                                          selectedState!,
                                          selectedCity!,
                                          selectedHotspot!,
                                          selectedRadius!
                                      );
                                      Navigator.pop(context);
                                      _showSnackbar("Hotspot updated successfully!");
                                    }
                                  }
                                } catch (e) {
                                  _showSnackbar("OTP Verification Failed: $e");
                                }
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text("Verify OTP"),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFCCAA00),
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("Cancel"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black54,
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateHotspot(String state, String city, String hotspot, String radius) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String phoneNumber = currentUser.phoneNumber ?? '';

        if (phoneNumber.isEmpty) {
          QuerySnapshot userDocs = await _firestore.collection('users')
              .where('uid', isEqualTo: currentUser.uid).get();
          if (userDocs.docs.isNotEmpty) {
            phoneNumber = userDocs.docs.first.id;
          }
        }

        if (phoneNumber.isNotEmpty) {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            _showSnackbar('Please enable location services');
            return;
          }

          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
            if (permission == LocationPermission.denied) {
              _showSnackbar('Location permissions are denied');
              return;
            }
          }

          if (permission == LocationPermission.deniedForever) {
            _showSnackbar('Location permissions are permanently denied');
            return;
          }

          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          await _firestore.collection('users').doc(phoneNumber).update({
            'locationDetails': {
              'state': state,
              'city': city,
              'hotspot': hotspot,
              'serviceRadius': radius,
              'latitude': position.latitude,
              'longitude': position.longitude,
              'geoPoint': GeoPoint(position.latitude, position.longitude),
            }
          });

          setState(() {
            currentState = state;
            currentCity = city;
            currentHotspot = hotspot;
            _screens[0] = _buildDashboardBody();
          });
        }
      }
    } catch (e) {
      _showSnackbar("Error updating hotspot: $e");
      rethrow;
    }
  }

  Future<String> _getServiceRadius(String phoneNumber) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(phoneNumber).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData['locationDetails'] != null) {
          return userData['locationDetails']['serviceRadius'] ?? 'Up to 1 km';
        }
      }
      return 'Up to 1 km';
    } catch (e) {
      return 'Up to 1 km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFDE7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFCCAA00),
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/imagefixify.png', height: 32),
            SizedBox(width: 8),
            Text(
              'FIXIFY',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),

          // Booking popup listener
          // In the build method of _DashboardScreenState, replace the StreamBuilder with:
          if (_bookingStream != null)
            StreamBuilder<QuerySnapshot>(
              stream: _bookingStream,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  // Get the first pending booking
                  var bookingDoc = snapshot.data!.docs.first;
                  Map<String, dynamic> bookingData = bookingDoc.data() as Map<String, dynamic>;

                  // Show the popup
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RAJGAD GALAXY - 143 Floor',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'DESCRIPTION: FAN REPAIR',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _handleBookingResponse(bookingDoc.id, true);
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFCCAA00),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: Text(
                                        'ACCEPT',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _handleBookingResponse(bookingDoc.id, false);
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey.shade200,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      child: Text(
                                        'DECLINE',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  });
                }

                return SizedBox.shrink();
              },
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            selectedItemColor: Color(0xFFCCAA00),
            unselectedItemColor: Colors.grey.shade600,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            elevation: 10,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.payment_outlined),
                activeIcon: Icon(Icons.payment),
                label: 'Payments',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardScreenBody extends StatelessWidget {
  final String? currentHotspot;
  final bool availabilityToggle;
  final TimeOfDay? availabilityEndTime;
  final VoidCallback onHotspotTap;
  final Function(bool) onAvailabilityChanged;
  final VoidCallback onTimeChange;
  final bool isLoading;
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  const DashboardScreenBody({
    Key? key,
    this.currentHotspot,
    required this.availabilityToggle,
    this.availabilityEndTime,
    required this.onHotspotTap,
    required this.onAvailabilityChanged,
    required this.onTimeChange,
    required this.isLoading,
    required this.firestore,
    required this.auth,
  }) : super(key: key);

  String _formatScheduleDate(dynamic dateField) {
    if (dateField == null) return 'Immediate';
    if (dateField is Timestamp) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(dateField.toDate());
    }
    return dateField.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Color(0xFFCCAA00),
          strokeWidth: 2,
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Location Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_pin, color: Color(0xFFCCAA00), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'SERVICE LOCATION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  GestureDetector(
                    onTap: onHotspotTap,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, color: Color(0xFFCCAA00), size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentHotspot != null
                                  ? currentHotspot!
                                  : 'Select your hotspot',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right, color: Colors.grey.shade500),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Availability Card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Color(0xFFCCAA00), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'AVAILABILITY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Set Your Availability',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (availabilityToggle && availabilityEndTime != null)
                            Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Until ${availabilityEndTime!.format(context)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Transform.scale(
                        scale: 0.9,
                        child: Switch.adaptive(
                          value: availabilityToggle,
                          onChanged: onAvailabilityChanged,
                          activeColor: Colors.white,
                          activeTrackColor: Color(0xFFCCAA00),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  if (availabilityToggle)
                    Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: onTimeChange,
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Change Availability Time',
                            style: TextStyle(
                              color: Color(0xFFCCAA00),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Status Indicator
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: availabilityToggle
                  ? Color(0xFFE8F5E9)
                  : Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: availabilityToggle
                    ? Color(0xFF81C784)
                    : Color(0xFFEF9A9A),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  availabilityToggle ? Icons.check_circle : Icons.error,
                  color: availabilityToggle
                      ? Color(0xFF2E7D32)
                      : Color(0xFFC62828),
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    availabilityToggle
                        ? "You're currently available for bookings"
                        : "You're currently unavailable for bookings",
                    style: TextStyle(
                      color: availabilityToggle
                          ? Color(0xFF2E7D32)
                          : Color(0xFFC62828),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // Upcoming Bookings Section
          Text(
            'UPCOMING BOOKINGS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: firestore.collection('bookings')
                .where('providerPhone', isEqualTo: auth.currentUser?.phoneNumber ?? '')
                .where('status', isEqualTo: 'accepted')
                .where('bookingType', isEqualTo: 'scheduled')
                .orderBy('scheduleDate')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/6902611.png',
                        height: 50,
                        width: 50,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No upcoming bookings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'When you have bookings, they will appear here',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var booking = snapshot.data!.docs[index];
                  var bookingData = booking.data() as Map<String, dynamic>;
                  String scheduleDate = _formatScheduleDate(bookingData['scheduleDate']);

                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bookingData['service'] ?? 'Service',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text('Customer: ${bookingData['customerName']}'),
                          SizedBox(height: 4),
                          Text('Date: $scheduleDate'),
                          SizedBox(height: 4),
                          Text('Charge: ₹${bookingData['visitingCharge'] ?? 0}'),
                          SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {

                              },
                              child: Text('VIEW DETAILS'),
                              style: TextButton.styleFrom(
                                foregroundColor: Color(0xFFCCAA00),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}