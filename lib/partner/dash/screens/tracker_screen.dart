import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrackerScreen extends StatefulWidget {
  final String bookingId;

  const TrackerScreen({Key? key, required this.bookingId}) : super(key: key);

  @override
  _TrackerScreenState createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _currentStatus = 'accepted';
  int _selectedTime = 10;
  final List<int> _timeOptions = [10, 15, 20, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Service Tracker'),
        backgroundColor: Color(0xFFCCAA00),
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('bookings').doc(widget.bookingId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          var bookingData = snapshot.data!.data() as Map<String, dynamic>;
          final String service = bookingData['service'] ?? 'Service';
          final String customerName = bookingData['customerName'] ?? 'Customer';
          final String address = bookingData['address'] ?? 'Address';
          final String flatNo = bookingData['flatNo'] ?? '';
          final String orderId = widget.bookingId.substring(0, 8).toUpperCase();

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Accepted Section
                _buildSection(
                  title: 'ORDER ACCEPTED',
                  subtitle: 'DESCRIPTION : $service',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RAJGAD GALAXY - $customerName',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 16),
                          SizedBox(width: 8),
                          Text('Contact Client'),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text('FLAT NO $flatNo'),
                    ],
                  ),
                ),

                // Time Selection Section
                if (_currentStatus == 'accepted') ...[
                  SizedBox(height: 20),
                  Text(
                    'SELECT TIME TO REACH',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _timeOptions.map((time) {
                      return ChoiceChip(
                        label: Text('<$time MINUTES'),
                        selected: _selectedTime == time,
                        onSelected: (selected) {
                          setState(() {
                            _selectedTime = time;
                          });
                        },
                        selectedColor: Color(0xFFCCAA00),
                        labelStyle: TextStyle(
                          color: _selectedTime == time ? Colors.black : Colors.grey,
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        _updateStatus('en_route');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFCCAA00),
                        minimumSize: Size(200, 50),
                      ),
                      child: Text(
                        'RECEIVING IN $_selectedTime MINUTES',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ],

                // Reached Section
                if (_currentStatus == 'en_route') ...[
                  SizedBox(height: 20),
                  _buildSection(
                    title: 'Rajgad',
                    subtitle: 'Check Backing',
                    content: Column(
                      children: [
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            _updateStatus('reached');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFCCAA00),
                            minimumSize: Size(double.infinity, 50),
                          ),
                          child: Text(
                            'Reached',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'RAJGAD GALAXY - $customerName FLAT NO $flatNo',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],

                // Diagnosing Section
                if (_currentStatus == 'reached') ...[
                  SizedBox(height: 20),
                  _buildSection(
                    title: 'ORDERID: $orderId',
                    subtitle: 'DIAGNOSING',
                    content: Column(
                      children: [
                        Text('DIGITAL', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Check Backing'),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            _updateStatus('diagnosed');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFCCAA00),
                            minimumSize: Size(double.infinity, 50),
                          ),
                          child: Text(
                            'DIAGNOSED',
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            _updateStatus('repaired');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: Size(double.infinity, 50),
                          ),
                          child: Text(
                            'REPAIRED',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'REPAIRED GALAXY - $customerName FLAT NO $flatNo',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],

                // Repairing Section
                if (_currentStatus == 'diagnosed') ...[
                  SizedBox(height: 20),
                  _buildSection(
                    title: 'ORDERID: $orderId',
                    subtitle: 'REPAIRING',
                    content: Column(
                      children: [
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            _updateStatus('completed');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: Size(double.infinity, 50),
                          ),
                          child: Text(
                            'service completed',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'RAJGAD GALAXY - $customerName FLAT NO $flatNo',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],

                // Invoice Section
                if (_currentStatus == 'completed') ...[
                  SizedBox(height: 20),
                  _buildSection(
                    title: 'GENERATE INVOICE',
                    content: Column(
                      children: [
                        SizedBox(height: 10),
                        Text(
                          'REPAIRED GALAXY - $customerName FLAT NO $flatNo',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],

                // Official Conservation Section (repeated as in image)
                if (_currentStatus == 'completed') ...[
                  SizedBox(height: 20),
                  for (int i = 0; i < 5; i++)
                    Column(
                      children: [
                        _buildSection(
                          title: 'OFFICIAL CONSERVATION',
                          content: Column(
                            children: [
                              SizedBox(height: 10),
                              Text(
                                'REPAIRED GALAXY - $customerName FLAT NO $flatNo',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? subtitle,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      await _firestore.collection('bookings').doc(widget.bookingId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        _currentStatus = newStatus;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }
}