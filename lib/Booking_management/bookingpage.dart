import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fixifypartner/Booking_management/bookingstatus.dart';

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

class _BookingPageState extends State<BookingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isBookNow = true;
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay(hour: 9, minute: 0);
  String selectedService = "";
  String selectedTimeSlot = "9:00 AM"; // Default value
  Map<String, dynamic>? currentUserData;
  bool isLoading = true;
  String? errorMessage;
  final TextEditingController serviceController = TextEditingController();

  // Default service descriptions based on service type
  final Map<String, String> defaultServiceDescriptions = {
    'electrician': 'Electrical repair service',
    'plumber': 'Plumbing repair service',
    'carpenter': 'Furniture repair service',
    'painter': 'Wall painting service',
  };

  @override
  void initState() {
    super.initState();

    // Initialize with available status
    isBookNow = widget.isAvailable;

    // Initialize tab controller - index 0 for BOOK NOW, index 1 for SCHEDULE BOOKING
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.isAvailable ? 0 : 1, // Set initial tab based on availability
    );

    // Add listener to tab controller to ensure isBookNow is updated with tab changes
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          isBookNow = _tabController.index == 0;
        });
      }
    });

    if (!widget.isAvailable) {
      // If not available, force Schedule Booking
      isBookNow = false;
      // Disable the "Book Now" tab for unavailable providers
      Future.delayed(Duration.zero, () {
        _tabController.animateTo(1); // Move to Schedule Booking tab
      });
    }

    // Set default date - today if available, tomorrow if not
    selectedDate = widget.isAvailable
        ? DateTime.now()
        : DateTime.now().add(Duration(days: 1));

    // Load user data from Firestore
    _loadCurrentUserData();

    // Set default service based on service type
    selectedService = defaultServiceDescriptions[widget.serviceType.toLowerCase()] ??
        "General ${widget.serviceType} service";
    serviceController.text = selectedService;
  }

  @override
  void dispose() {
    _tabController.dispose();
    serviceController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserData() async {
    setState(() => isLoading = true);
    try {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      String? phoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber;

      if (userId != null) {
        var docSnapshot = await FirebaseFirestore.instance
            .collection('customers')
            .doc(userId)
            .get();
        if (docSnapshot.exists) {
          currentUserData = docSnapshot.data();
        }
      } else if (phoneNumber != null) {
        var querySnapshot = await FirebaseFirestore.instance
            .collection('customers')
            .where('phone', isEqualTo: phoneNumber)
            .limit(1)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          currentUserData = querySnapshot.docs.first.data();
        }
      }

      // Check if we still couldn't get user data
      if (currentUserData == null) {
        setState(() {
          errorMessage = "Could not load user data. Please ensure you're logged in correctly.";
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        errorMessage = "Error loading user data: $e";
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  List<DateTime> _getNextSevenDays() {
    return List.generate(7, (index) => DateTime.now().add(Duration(days: index)));
  }

  // Modified to get half-hour intervals
  List<Map<String, dynamic>> _getTimeSlots() {
    final List<Map<String, dynamic>> slots = [];

    // Generate slots from 9:00 AM to 7:00 PM in 30-minute intervals
    for (int hour = 9; hour <= 19; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        // Skip 7:30 PM
        if (hour == 19 && minute == 30) continue;

        final tod = TimeOfDay(hour: hour, minute: minute);
        slots.add({
          'time': _formatTimeOfDay(tod),
          'value': tod,
        });
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
    // Double-check the booking type based on the current tab
    // This ensures we always respect the active tab when creating bookings
    final bool currentIsBookNow = _tabController.index == 0;

    print("Creating booking with isBookNow = $currentIsBookNow (Tab index: ${_tabController.index})");

    // Validate service description
    if (serviceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please describe the service you need"))
      );
      return;
    }

    // Validate time slot for scheduled bookings
    if (!currentIsBookNow && selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please select a time for your booking"))
      );
      return;
    }

    // Check for user data
    if (currentUserData == null) {
      // Try loading user data one more time
      await _loadCurrentUserData();

      // If still null, show error and return
      if (currentUserData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Unable to create booking. User data not available. Please ensure you're logged in properly."))
        );
        return;
      }
    }

    try {
      // Get current user details
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      String? userPhone = currentUserData!['phone'] ?? FirebaseAuth.instance.currentUser?.phoneNumber;
      String? userName = currentUserData!['name'] ?? "Customer";

      if (userId == null && userPhone == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Unable to identify user. Please log in again."))
        );
        return;
      }

      // Generate a document ID before adding the document
      DocumentReference bookingRef = FirebaseFirestore.instance.collection('bookings').doc();

      final booking = {
        'bookingType': currentIsBookNow ? 'now' : 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
        'scheduledDate': currentIsBookNow
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute
        )),
        'bookingId': bookingRef.id, // Add the ID here directly
        'customerId': FirebaseAuth.instance.currentUser?.uid,
        'customerPhone': userPhone,
        'customerName': userName,
        'providerId': widget.serviceProvider['uid'],
        'providerName': widget.serviceProvider['name'],
        'providerPhone': widget.serviceProvider['phone'],
        'serviceType': widget.serviceType,
        'service': serviceController.text.trim(),
        'status': 'pending',
        'customerLocation': currentUserData!.containsKey('residenceDetails')
            ? currentUserData!['residenceDetails']
            : currentUserData!.containsKey('locationDetails')
            ? currentUserData!['locationDetails']
            : "Location not specified",
        'visitingCharge': widget.serviceProvider['visitingCharge'] ?? 220,
        'schedulingCharge': currentIsBookNow ? 0 : 20, // Add scheduling charge
      };

      // Create the document with the ID already set
      await bookingRef.set(booking);

      // Create notification for the service provider
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': widget.serviceProvider['uid'],
        'type': 'booking_request',
        'title': 'New Booking Request',
        'message': 'You have a new booking request from $userName',
        'bookingId': bookingRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false
      });

      // Navigate to the new status page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BookingStatusPage(
            bookingId: bookingRef.id,
            serviceProvider: widget.serviceProvider,
            serviceType: widget.serviceType,
            bookingType: currentIsBookNow ? 'now' : 'scheduled',
            scheduledDateTime: currentIsBookNow
                ? DateTime.now()
                : DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                selectedTime.hour,
                selectedTime.minute
            ),
            initialStatus: BookingStatus.loading,
          ),
        ),
      );
    } catch (e) {
      print('Error creating booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to create booking: ${e.toString()}"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Book Service", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.indigo[800],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.indigo[800]))
          : errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[400]),
              SizedBox(height: 20),
              Text(
                errorMessage!,
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadCurrentUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[800],
                  foregroundColor: Colors.white,
                ),
                child: Text("Try Again"),
              )
            ],
          ),
        ),
      )
          : Column(
        children: [
          // Custom Tab Bar
          Container(
            color: Colors.indigo[800],
            child: TabBar(
              controller: _tabController,
              onTap: (index) {
                // Only allow tab change if service provider is available
                if (!widget.isAvailable && index == 0) {
                  _tabController.animateTo(1); // Keep on Schedule Booking tab
                  return;
                }
                setState(() {
                  isBookNow = index == 0;
                  print("Tab changed: isBookNow = $isBookNow");
                });
              },
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              indicatorColor: Colors.amber,
              indicatorWeight: 3,
              tabs: [
                Tab(
                  child: Text(
                    "BOOK NOW",
                    style: TextStyle(
                      color: widget.isAvailable ? Colors.white : Colors.white38,
                    ),
                  ),
                ),
                Tab(text: "SCHEDULE BOOKING"),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: widget.isAvailable
                  ? AlwaysScrollableScrollPhysics()
                  : NeverScrollableScrollPhysics(),
              children: [
                // BOOK NOW Tab
                _buildBookingContent(isNow: true),

                // SCHEDULE BOOKING Tab
                _buildBookingContent(isNow: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingContent({required bool isNow}) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected Services Header
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo[50]!, Colors.indigo[100]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Service Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo[800]),
                  ),
                  SizedBox(height: 16),

                  // Service provider info
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.indigo[800],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ]
                        ),
                        child: Icon(
                          widget.serviceType.toLowerCase() == 'electrician'
                              ? Icons.lightbulb_outline
                              : widget.serviceType.toLowerCase() == 'plumber'
                              ? Icons.plumbing
                              : widget.serviceType.toLowerCase() == 'carpenter'
                              ? Icons.handyman
                              : widget.serviceType.toLowerCase() == 'painter'
                              ? Icons.format_paint
                              : Icons.build,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${widget.serviceProvider["name"] ?? "Service Provider"}",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Visiting charges - ₹${widget.serviceProvider["visitingCharge"]?.toString() ?? "220"}",
                              style: TextStyle(fontSize: 14, color: Colors.indigo[700], fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20),

                  // Service description input field
                  Text(
                    "Describe what service you need",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                  ),
                  SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          )
                        ]
                    ),
                    child: TextField(
                      controller: serviceController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "E.g., Fan not working, Tap leakage, Need to fix a table...",
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: IconButton(
                            icon: Icon(Icons.cancel_outlined, color: Colors.grey[600]),
                            onPressed: () => serviceController.clear(),
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.indigo[400]!),
                        ),
                        contentPadding: EdgeInsets.all(12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          selectedService = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Date and time selection for scheduled bookings
          if (!isNow)
            _buildDateTimeSelection(),

          SizedBox(height: 20),

          // Payment Summary
          _buildPaymentSummary(isNow: isNow),

          SizedBox(height: 24),

          // Request Booking Button
          Container(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _createBooking,
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
                "Request Booking",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSelection() {
    List<DateTime> nextDays = _getNextSevenDays();
    List<Map<String, dynamic>> timeSlots = _getTimeSlots();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber[50]!, Colors.amber[100]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.amber[800]),
                SizedBox(width: 8),
                Text(
                  "Select Date and Time",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber[800]),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              "A ${widget.serviceType} usually takes around 45-60 minutes to complete a service",
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
            SizedBox(height: 16),

            // Date selection
            Text(
              "Select Date",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
            SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: nextDays.map((date) {
                  bool isSelected = selectedDate.day == date.day &&
                      selectedDate.month == date.month &&
                      selectedDate.year == date.year;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: _dateButton(
                      DateFormat('EEE').format(date),
                      DateFormat('d').format(date),
                      isSelected,
                      date,
                    ),
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: 20),

            // Time selection with dropdown
            Text(
              "Select Time",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
            ),
            SizedBox(height: 10),

            // Dropdown for time selection - improved UI
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber[100]!.withOpacity(0.5),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ],
              ),
              child: DropdownButtonFormField<TimeOfDay>(
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.access_time, color: Colors.amber[700]),
                ),
                icon: Icon(Icons.arrow_drop_down, color: Colors.amber[700]),
                hint: Text("Select time slot"),
                isExpanded: true,
                onChanged: (TimeOfDay? timeOfDay) {
                  if (timeOfDay != null) {
                    setState(() {
                      selectedTime = timeOfDay;
                      selectedTimeSlot = _formatTimeOfDay(timeOfDay);
                    });
                  }
                },
                value: selectedTime,
                items: timeSlots.map((slot) {
                  return DropdownMenuItem<TimeOfDay>(
                    value: slot['value'],
                    child: Text(slot['time']),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateButton(String day, String date, bool isSelected, DateTime fullDate) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedDate = fullDate;
        });
      },
      child: Container(
        width: 60,
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber[700] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? Colors.amber[700]! : Colors.grey[300]!),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.amber[700]!.withOpacity(0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ] : null,
        ),
        child: Column(
          children: [
            Text(
                day,
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? Colors.white : Colors.grey[700],
                )
            ),
            SizedBox(height: 4),
            Text(
                date,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.grey[900],
                )
            ),
          ],
        ),
        alignment: Alignment.center,
      ),
    );
  }

  Widget _buildPaymentSummary({required bool isNow}) {
    // Check current tab for accurate payment summary
    final currentIsBookNow = _tabController.index == 0;
    final actualIsNow = isNow && (isNow == currentIsBookNow);

    final visitingCharge = widget.serviceProvider["visitingCharge"] ?? 220;
    final discount = (visitingCharge * 0.20).round(); // 20% discount
    final platformFee = 15;
    final scheduleCharge = actualIsNow ? 0 : 20; // Schedule booking charge

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.indigo[800]),
                SizedBox(width: 8),
                Text(
                  "Payment Summary",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo[800]),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildPaymentRow("Visiting charges", "₹$visitingCharge"),
            _buildPaymentRow("Discount (20%)", "-₹$discount", textColor: Colors.green[700]),
            _buildPaymentRow("Platform Fee", "₹$platformFee"),
            if (!actualIsNow) _buildPaymentRow("Schedule Booking Fee", "₹$scheduleCharge", textColor: Colors.amber[800]),
            _buildPaymentRow("Service Charges", "To be decided", isBold: true),

            Divider(height: 24, thickness: 1, color: Colors.grey[300]),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "To Pay Now",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[900],
                  ),
                ),
                Text(
                  "₹${visitingCharge - discount + platformFee + scheduleCharge}",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[900],
                  ),
                ),
              ],
            ),

            SizedBox(height: 12),

            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey[700]),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Final invoice will be generated after service completion",
                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String title, String amount, {bool isBold = false, Color? textColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor ?? Colors.grey[800],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor ?? Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}

