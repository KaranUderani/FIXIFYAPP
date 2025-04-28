import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class Bookings extends StatefulWidget {
  @override
  _BookingsPageState createState() => _BookingsPageState();
}

class _BookingsPageState extends State<Bookings> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  List<Map<String, dynamic>> bookings = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      bookings = [];
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception("User not logged in");

      // Get all bookings where user is either customer or provider
      final customerQuery = FirebaseFirestore.instance
          .collection('bookings')
          .where('customerId', isEqualTo: userId);

      final providerQuery = FirebaseFirestore.instance
          .collection('bookings')
          .where('providerId', isEqualTo: userId);

      final customerSnapshot = await customerQuery.get();
      final providerSnapshot = await providerQuery.get();

      final allBookings = [
        ...customerSnapshot.docs.map((doc) => _processBookingDoc(doc, 'customer')),
        ...providerSnapshot.docs.map((doc) => _processBookingDoc(doc, 'provider')),
      ];

      // Sort by createdAt descending
      allBookings.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        return (bDate ?? Timestamp.now()).compareTo(aDate ?? Timestamp.now());
      });

      setState(() {
        bookings = allBookings;
        isLoading = false;
      });

      print('Loaded ${bookings.length} bookings');
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() {
        errorMessage = "Failed to load bookings. Please try again.";
        isLoading = false;
      });
    }
  }

  Map<String, dynamic> _processBookingDoc(DocumentSnapshot doc, String userRole) {
    final data = doc.data() as Map<String, dynamic>;
    return {
      ...data,
      'id': doc.id,
      'userRole': userRole,
    };
  }

  List<Map<String, dynamic>> _getFilteredBookings(String filter) {
    return bookings.where((booking) {
      switch (filter) {
        case 'active':
          return booking['status'] == 'pending' ||
              booking['status'] == 'accepted' ||
              booking['status'] == 'in_progress';
        case 'completed':
          return booking['status'] == 'completed';
        case 'cancelled':
          return booking['status'] == 'cancelled' ||
              booking['status'] == 'rejected';
        default:
          return false;
      }
    }).toList();
  }

  // Add the missing error view method
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          SizedBox(height: 16),
          Text(
            errorMessage ?? 'Unknown error occurred',
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadBookings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[800],
              foregroundColor: Colors.white,
            ),
            child: Text("Retry"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("My Bookings", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo[800],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadBookings,
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          tabs: [
            Tab(text: "ACTIVE"),
            Tab(text: "COMPLETED"),
            Tab(text: "CANCELLED"),
          ],
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.indigo[800]))
          : errorMessage != null
          ? _buildErrorView()
          : TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList('active'),
          _buildBookingsList('completed'),
          _buildBookingsList('cancelled'),
        ],
      ),
    );
  }

  Widget _buildBookingsList(String filter) {
    final filteredBookings = _getFilteredBookings(filter);

    if (filteredBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              filter == 'active' ? "No active bookings" :
              filter == 'completed' ? "No completed bookings" :
              "No cancelled bookings",
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        return _BookingCard(booking: booking, onCancel: _cancelBooking);
      },
    );
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': 'cancelled'});
      _loadBookings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to cancel booking")),
      );
    }
  }
}

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final Function(String) onCancel;

  const _BookingCard({required this.booking, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    final status = booking['status'];
    final isCustomer = booking['userRole'] == 'customer';
    final otherPartyName = isCustomer
        ? booking['providerName'] ?? 'Provider'
        : booking['customerName'] ?? 'Customer';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(booking['createdAt']),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(status)),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.build, color: Colors.indigo[800]),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['service'] ?? 'Service',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'ID: ${booking['id'].substring(0, 8)}...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Provider', style: TextStyle(color: Colors.grey)),
                      Text(otherPartyName),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type', style: TextStyle(color: Colors.grey)),
                      Text(booking['bookingType'] == 'now' ? 'Immediate' : 'Scheduled'),
                    ],
                  ),
                ),
              ],
            ),
            if (status == 'completed') ...[
              Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Amount'),
                  Text(
                    '₹${_calculateAmount(booking)}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
            if (isCustomer && status == 'pending') ...[
              Divider(height: 24),
              OutlinedButton(
                onPressed: () => onCancel(booking['id']),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red),
                ),
                child: Text('Cancel Booking'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'No date';
    return DateFormat('MMM d, yyyy · h:mm a').format(timestamp.toDate());
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'accepted': return Colors.blue;
      case 'in_progress': return Colors.blue;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Pending';
      case 'accepted': return 'Accepted';
      case 'in_progress': return 'In Progress';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      case 'rejected': return 'Rejected';
      default: return status;
    }
  }

  String _calculateAmount(Map<String, dynamic> booking) {
    final base = booking['visitingCharge'] ?? 220;
    final discount = (base * 0.2).round();
    final fee = booking['bookingType'] == 'now' ? 15 : 35;
    return (base - discount + fee).toString();
  }
}