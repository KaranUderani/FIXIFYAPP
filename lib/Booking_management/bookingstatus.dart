import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fixifypartner/user/userdash/HomeScreen.dart'; // Adjust import to your actual home page

enum BookingStatus {
  loading,
  confirmed,
  declined
}

class BookingStatusPage extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> serviceProvider;
  final String serviceType;
  final String bookingType;
  final DateTime scheduledDateTime;
  final BookingStatus initialStatus;

  BookingStatusPage({
    required this.bookingId,
    required this.serviceProvider,
    required this.serviceType,
    required this.bookingType,
    required this.scheduledDateTime,
    this.initialStatus = BookingStatus.loading,
  });

  @override
  _BookingStatusPageState createState() => _BookingStatusPageState();
}

class _BookingStatusPageState extends State<BookingStatusPage> {
  late BookingStatus currentStatus;
  late Stream<DocumentSnapshot> bookingStream;
  bool isListening = true;

  @override
  void initState() {
    super.initState();
    currentStatus = widget.initialStatus;

    // Set up stream to listen for booking status changes
    bookingStream = FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .snapshots();

    // Start listening to changes in booking status
    if (currentStatus == BookingStatus.loading) {
      _listenToBookingStatus();
    }
  }

  void _listenToBookingStatus() {
    bookingStream.listen((snapshot) {
      if (!isListening || !mounted) return;

      if (snapshot.exists) {
        final bookingData = snapshot.data() as Map<String, dynamic>;
        final status = bookingData['status'] as String;

        if (status == 'accepted') {
          setState(() {
            currentStatus = BookingStatus.confirmed;
          });
          // Stop listening once we have a final status
          isListening = false;
        } else if (status == 'declined') {
          setState(() {
            currentStatus = BookingStatus.declined;
          });
          // Stop listening once we have a final status
          isListening = false;
        }
        // If status is still 'pending', continue listening
      }
    });
  }

  @override
  void dispose() {
    isListening = false;
    super.dispose();
  }

  // Format the date to display
  String _formatDate(DateTime dateTime) {
    return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
  }

  // Navigate to home screen
  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
          (route) => false,
    );
  }

  // Cancel booking request and go back to home
  Future<void> _cancelBookingRequest() async {
    try {
      // Show confirmation dialog
      bool confirmCancel = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Cancel Booking"),
            content: Text("Are you sure you want to cancel this booking request?"),
            actions: <Widget>[
              TextButton(
                child: Text("No", style: TextStyle(color: Colors.grey)),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text("Yes", style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      ) ?? false;

      if (confirmCancel) {
        // Update booking status to cancelled
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .update({'status': 'cancelled'});

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Booking cancelled successfully"),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home
        _navigateToHome();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to cancel booking: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Booking Status", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: _buildStatusContent(),
      ),
    );
  }

  Widget _buildStatusContent() {
    switch (currentStatus) {
      case BookingStatus.loading:
        return _buildLoadingStatus();
      case BookingStatus.confirmed:
        return _buildConfirmedStatus();
      case BookingStatus.declined:
        return _buildDeclinedStatus();
    }
  }

  Widget _buildLoadingStatus() {
    // Check if this is a scheduled booking
    bool isScheduled = widget.bookingType != 'now';

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          // Service provider circular image
          Container(
            padding: EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green[300]!, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(75),
              child: Image.asset(
                'assets/images/experienced_help.png',
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            "${widget.serviceType.toUpperCase()} - ${widget.serviceProvider['name']?.toUpperCase() ?? 'SERVICE PROVIDER'}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          // Rating stars
          SizedBox(height: 30),
          Text(
            "Waiting for Confirmation",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          SizedBox(height: 12),
          Text(
            "Your booking request has been sent to ${widget.serviceProvider['name']}",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),

          // Booking Details Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey[50]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                      Icons.handyman,
                      "Service Type",
                      widget.serviceType,
                      Colors.indigo[700]!
                  ),
                  Divider(height: 24, thickness: 1, color: Colors.grey[200]),
                  _buildDetailRow(
                      Icons.event,
                      "Booking Type",
                      widget.bookingType == 'now' ? "Book Now" : "Scheduled",
                      Colors.amber[700]!
                  ),
                  Divider(height: 24, thickness: 1, color: Colors.grey[200]),
                  _buildDetailRow(
                      Icons.access_time,
                      "Date & Time",
                      _formatDate(widget.scheduledDateTime),
                      Colors.green[700]!
                  ),
                  Divider(height: 24, thickness: 1, color: Colors.grey[200]),
                  _buildDetailRow(
                      Icons.confirmation_number,
                      "Booking ID",
                      widget.bookingId,
                      Colors.purple[700]!
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 30),

          // Only show loading indicator for "Book Now" option
          if (!isScheduled)
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
            ),

          SizedBox(height: 30),

          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.bookingType == 'now'
                        ? "The service provider will confirm your booking shortly."
                        : "Your booking is being processed. The service provider will confirm your scheduled appointment soon.",
                    style: TextStyle(fontSize: 14, color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          // Different button layouts based on booking type
          if (isScheduled)
          // For scheduled bookings: Row with Cancel Request and Continue Exploring
            Row(
              children: [
                // Cancel Request button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _cancelBookingRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      "Cancel Request",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

                // Spacer between buttons
                SizedBox(width: 12),

                // Continue Exploring button
                Expanded(
                  child: ElevatedButton(
                    onPressed: _navigateToHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo[800],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      "Continue Exploring",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            )
          else
          // For Book Now: Only Cancel Request button (full width)
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _cancelBookingRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  "Cancel Request",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmedStatus() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle, color: Colors.green[600], size: 80),
          ),
          SizedBox(height: 24),
          Text(
            "Booking Confirmed!",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800]),
          ),
          SizedBox(height: 12),
          Text(
            widget.bookingType == 'now'
                ? "${widget.serviceProvider['name']} is on the way to your location"
                : "Your appointment with ${widget.serviceProvider['name']} is confirmed",
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),

          // Service provider details
          Container(
            padding: EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green[300]!, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: Image.asset(
                'assets/images/experienced_help.png',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            "${widget.serviceType.toUpperCase()} - ${widget.serviceProvider['name']?.toUpperCase() ?? 'SERVICE PROVIDER'}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          // Rating stars
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
                  (index) => Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 18
              ),
            ),
          ),

          SizedBox(height: 30),

          // Booking Details Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey[50]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                      Icons.handyman,
                      "Service Type",
                      widget.serviceType,
                      Colors.indigo[700]!
                  ),
                  Divider(height: 24, thickness: 1, color: Colors.grey[200]),
                  _buildDetailRow(
                      Icons.event,
                      "Booking Type",
                      widget.bookingType == 'now' ? "Book Now" : "Scheduled",
                      Colors.amber[700]!
                  ),
                  Divider(height: 24, thickness: 1, color: Colors.grey[200]),
                  _buildDetailRow(
                      Icons.access_time,
                      "Date & Time",
                      _formatDate(widget.scheduledDateTime),
                      Colors.green[700]!
                  ),
                  Divider(height: 24, thickness: 1, color: Colors.grey[200]),
                  _buildDetailRow(
                      Icons.confirmation_number,
                      "Booking ID",
                      widget.bookingId,
                      Colors.purple[700]!
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 30),

          // Info message
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.green[700]),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.bookingType == 'now'
                        ? "Your service provider is on the way. You'll be notified when they arrive."
                        : "Your appointment is confirmed for ${_formatDate(widget.scheduledDateTime)}. Don't forget to keep your phone handy.",
                    style: TextStyle(fontSize: 14, color: Colors.green[800]),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          // Cancel appointment button for scheduled bookings
          if (widget.bookingType != 'now')
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 16),
              child: ElevatedButton(
                onPressed: _cancelBookingRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[400],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  "Cancel Appointment",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          // Continue Exploring Button
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navigateToHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[800],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                "Return to Home",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeclinedStatus() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cancel, color: Colors.red[600], size: 80),
          ),
          SizedBox(height: 24),
          Text(
            "Booking Declined",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red[800]),
          ),
          SizedBox(height: 12),
          Text(
            "Sorry, your booking request has been declined by ${widget.serviceProvider['name']}",
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30),

          // Service provider details
          Container(
            padding: EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(60),
              child: Image.asset(
                'assets/images/experienced_help.png',
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                color: Colors.grey[400],
                colorBlendMode: BlendMode.saturation,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            "${widget.serviceType.toUpperCase()} - ${widget.serviceProvider['name']?.toUpperCase() ?? 'SERVICE PROVIDER'}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),

          SizedBox(height: 30),

          // Booking Details Card
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                      Icons.handyman,
                      "Service Type",
                      widget.serviceType,
                      Colors.grey[700]!
                  ),
                  Divider(height: 24, thickness: 1, color: Colors.grey[200]),
                  _buildDetailRow(
                      Icons.event,
                      "Booking Type",
                      widget.bookingType == 'now' ? "Book Now" : "Scheduled",
                      Colors.grey[700]!
                  ),
                  Divider(height: 24, thickness: 1, color: Colors.grey[200]),
                  _buildDetailRow(
                      Icons.access_time,
                      "Date & Time",
                      _formatDate(widget.scheduledDateTime),
                      Colors.grey[700]!
                  ),
                  Divider(height: 24, thickness: 1, color: Colors.grey[200]),
                  _buildDetailRow(
                      Icons.confirmation_number,
                      "Booking ID",
                      widget.bookingId,
                      Colors.grey[700]!
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 30),

          // Info message
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "We have other service providers available. Please return to the home screen to book with someone else.",
                    style: TextStyle(fontSize: 14, color: Colors.blue[800]),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          // Return to Home Button
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navigateToHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[800],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: Text(
                "Find Another Service Provider",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  label,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[900]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}