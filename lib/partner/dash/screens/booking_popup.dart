import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingPopup extends StatelessWidget {
  final String bookingId;
  final String customerName;
  final String service;
  final String scheduleDate;
  final int visitingCharge;
  final Function(bool) onResponse;

  const BookingPopup({
    Key? key,
    required this.bookingId,
    required this.customerName,
    required this.service,
    required this.scheduleDate,
    required this.visitingCharge,
    required this.onResponse,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NEW BOOKING REQUEST',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Customer: $customerName',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'Service: $service',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'Date: $scheduleDate',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              'Visiting Charge: ₹$visitingCharge',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onResponse(false),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.red),
                    ),
                    child: Text('DECLINE', style: TextStyle(color: Colors.red)),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onResponse(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFCCAA00),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('ACCEPT', style: TextStyle(color: Colors.black)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}