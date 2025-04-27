import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Booking Confirmation", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                "Booking Request Successful!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800]),
              ),
              SizedBox(height: 12),
              Text(
                "Your booking has been sent to ${serviceProvider['name']}",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
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
                          serviceType,
                          Colors.indigo[700]!
                      ),
                      Divider(height: 24, thickness: 1, color: Colors.grey[200]),
                      _buildDetailRow(
                          Icons.event,
                          "Booking Type",
                          bookingType == 'now' ? "Book Now" : "Scheduled",
                          Colors.amber[700]!
                      ),
                      Divider(height: 24, thickness: 1, color: Colors.grey[200]),
                      _buildDetailRow(
                          Icons.access_time,
                          "Date & Time",
                          DateFormat('MMM d, yyyy • h:mm a').format(scheduledDateTime),
                          Colors.green[700]!
                      ),
                      Divider(height: 24, thickness: 1, color: Colors.grey[200]),
                      _buildDetailRow(
                          Icons.confirmation_number,
                          "Booking ID",
                          bookingId,
                          Colors.purple[700]!
                      ),
                    ],
                  ),
                ),
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
                        "The ${serviceType.toLowerCase()} will confirm your booking shortly. You'll receive a notification when confirmed.",
                        style: TextStyle(fontSize: 14, color: Colors.blue[800]),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[800],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 3,
                  ),
                  child: Text(
                    "Return to Home",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
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