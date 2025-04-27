import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';


class BookingPage extends StatefulWidget {
  final Map<String, dynamic> serviceProvider;
  final bool isAvailable;
  final String serviceType;

  BookingPage({
    required this.serviceProvider,
    required this.isAvailable,
    required this.serviceType,
  });

  @override
  _BookingPageState createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  bool isBookNow = true;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay(hour: 10, minute: 0);
  String selectedService = "General Service";
  Map<String, dynamic>? currentUserData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    isBookNow = widget.isAvailable;
    _loadCurrentUserData();

    if (!widget.isAvailable) {
      isBookNow = false;
    }

    selectedDate = widget.isAvailable
        ? DateTime.now()
        : DateTime.now().add(Duration(days: 1));

    // Set default service based on service type
    switch (widget.serviceType.toLowerCase()) {
      case 'electrician':
        selectedService = "Fan repair";
        break;
      case 'plumber':
        selectedService = "Pipe repair";
        break;
      default:
        selectedService = "General Service";
    }
  }

  Future<void> _loadCurrentUserData() async {
    setState(() => isLoading = true);
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
            currentUserData = querySnapshot.docs.first.data();
          }
        }
      } else {
        var docSnapshot = await FirebaseFirestore.instance
            .collection('customers')
            .doc(userId)
            .get();
        if (docSnapshot.exists) {
          currentUserData = docSnapshot.data();
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<DateTime> _getNextSevenDays() {
    return List.generate(7, (index) => DateTime.now().add(Duration(days: index)));
  }

  List<TimeOfDay> _getTimeSlots() {
    List<TimeOfDay> slots = [];
    for (int hour = 10; hour <= 19; hour++) {
      slots.add(TimeOfDay(hour: hour, minute: 0));
      if (hour < 19) {
        slots.add(TimeOfDay(hour: hour, minute: 30));
      }
    }
    return slots;
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, tod.hour, tod.minute);
    return DateFormat.jm().format(dt);
  }

  Future<void> _createBooking() async {
    if (currentUserData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unable to create booking. User data not available."))
      );
      return;
    }

    try {
      final booking = {
        'customerId': FirebaseAuth.instance.currentUser?.uid,
        'customerPhone': currentUserData!['phone'],
        'customerName': currentUserData!['name'],
        'providerId': widget.serviceProvider['uid'],
        'providerName': widget.serviceProvider['name'],
        'providerPhone': widget.serviceProvider['phone'],
        'serviceType': widget.serviceType,
        'service': selectedService,
        'status': 'pending',
        'bookingType': isBookNow ? 'now' : 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
        'scheduledDate': isBookNow
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute
        )),
        'customerLocation': currentUserData!.containsKey('residenceDetails')
            ? currentUserData!['residenceDetails']
            : currentUserData!['locationDetails'],
        'visitingCharge': widget.serviceProvider['visitingCharge'] ?? 0,
      };

      DocumentReference bookingRef = await FirebaseFirestore.instance
          .collection('bookings')
          .add(booking);

      await bookingRef.update({'bookingId': bookingRef.id});

      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': widget.serviceProvider['uid'],
        'type': 'booking_request',
        'title': 'New Booking Request',
        'message': 'You have a new booking request from ${currentUserData!['name']}',
        'bookingId': bookingRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmationPage(
              bookingId: bookingRef.id,
              serviceProvider: widget.serviceProvider,
              serviceType: widget.serviceType,
              bookingType: isBookNow ? 'now' : 'scheduled',
              scheduledDateTime: isBookNow
                  ? DateTime.now()
                  : DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute
              )
          ),
        ),
      );
    } catch (e) {
      print('Error creating booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create booking. Please try again."))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Book ${widget.serviceType}", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange[300],
        centerTitle: true,
        elevation: 4,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Provider Information Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: widget.serviceProvider["profileImage"] != null &&
                          widget.serviceProvider["profileImage"].toString().startsWith('http')
                          ? NetworkImage(widget.serviceProvider["profileImage"]) as ImageProvider
                          : AssetImage("assets/images/profile image.png"),
                      backgroundColor: Colors.grey[300],
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.serviceProvider["name"] ?? widget.serviceType,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            widget.serviceProvider["experience"] ?? "Professional",
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.isAvailable ? Colors.green[100] : Colors.red[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.isAvailable ? "Available" : "Unavailable",
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isAvailable ? Colors.green[800] : Colors.red[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Selected Service
            Text(
              "Selected Services",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                          widget.serviceType.toLowerCase() == 'electrician'
                              ? Icons.electrical_services
                              : widget.serviceType.toLowerCase() == 'plumber'
                              ? Icons.plumbing
                              : Icons.build,
                          color: Colors.orange[700]),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${widget.serviceType} • ${widget.serviceProvider["name"] ?? "Professional"}",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Visiting charges • ₹ ${widget.serviceProvider["visitingCharge"]?.toString() ?? "220"}",
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 8),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.build, color: Colors.blue[700]),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedService,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "What services are you looking for?",
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.info_outline, color: Colors.orange[300]),
                  ],
                ),
              ),
            ),

            // Rest of the booking page UI remains the same...
            // [Previous code for booking type selection, date/time picker, payment summary, etc.]

            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[700],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Request Booking",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingConfirmationPage extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> serviceProvider;
  final String serviceType;
  final String bookingType;
  final DateTime scheduledDateTime;

  BookingConfirmationPage({
    required this.bookingId,
    required this.serviceProvider,
    required this.serviceType,
    required this.bookingType,
    required this.scheduledDateTime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Booking Confirmation"),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 80),
              SizedBox(height: 20),
              Text(
                "Booking Request Submitted!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "Your booking has been sent to ${serviceProvider['name']}",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.event, color: Colors.orange[700]),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Service Type", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                            Text(
                              serviceType,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Icon(Icons.event, color: Colors.orange[700]),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Booking Type", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                            Text(
                              bookingType == 'now' ? "Book Now" : "Scheduled",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.orange[700]),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Date & Time", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                            Text(
                              DateFormat('MMM d, yyyy • h:mm a').format(scheduledDateTime),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Icon(Icons.confirmation_number, color: Colors.orange[700]),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Booking ID", style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                            Text(
                              bookingId,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Text(
                "The ${serviceType.toLowerCase()} will confirm your booking shortly",
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[700],
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  "Go to Home",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}