import 'package:flutter/material.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderStatus; // 'accepted', 'reaching', 'diagnosing', 'repairing', 'completed'
  final String orderId;
  final String location;
  final String flatNo;

  const OrderDetailScreen({
    Key? key,
    required this.orderStatus,
    required this.orderId,
    required this.location,
    required this.flatNo,
  }) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool reached = false;
  bool diagnosed = false;
  bool repaired = false;
  bool notPossible = false;

  @override
  void initState() {
    super.initState();
    // Set initial state based on orderStatus
    switch(widget.orderStatus) {
      case 'reaching':
        break;
      case 'diagnosing':
        reached = true;
        break;
      case 'repairing':
        reached = true;
        diagnosed = true;
        break;
      case 'completed':
        reached = true;
        diagnosed = true;
        repaired = true;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (widget.orderStatus == 'accepted')
              _buildAcceptedView()
            else if (widget.orderStatus == 'reaching')
              _buildReachingView()
            else if (widget.orderStatus == 'diagnosing')
                _buildDiagnosingView()
              else if (widget.orderStatus == 'repairing')
                  _buildRepairingView()
                else if (widget.orderStatus == 'completed')
                    _buildCompletedView(),

            const SizedBox(height: 16),

            // Location and flat info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.location} - MR.XYZ',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'FLAT NO ${widget.flatNo}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (widget.orderStatus == 'accepted')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SELECT TIME TO REACH',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('< 10 MINUTES'),
                              Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('LEFT FOR LOCATION'),
                          ),
                        ),
                      ],
                    ),

                  if (widget.orderStatus != 'accepted' && widget.orderStatus != 'completed')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('contact'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Cancel Booking'),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  if (widget.orderStatus == 'reaching')
                    _buildStatusToggle('Reached', reached),

                  if (widget.orderStatus == 'diagnosing')
                    Column(
                      children: [
                        _buildStatusToggle('DIAGNOSED', diagnosed),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('REPAIR NOT POSSIBLE'),
                          ),
                        ),
                      ],
                    ),

                  if (widget.orderStatus == 'repairing')
                    _buildStatusToggle('REPAIRED', repaired),

                  if (widget.orderStatus == 'completed')
                    Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Fan repaired',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {},
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const Text('Light Bulb Replaced'),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: const [
                                  Text('SERVICE DONE'),
                                  Text('ENTER AMOUNT'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('GENERATE INVOICE'),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'HOW WAS YOUR EXPERIENCE WITH MR.XYZ?',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            5,
                                (index) => const Icon(
                              Icons.star_border,
                              color: Colors.grey,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your feedback will help us VALIDATE PARTNER EXPERIENCE',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F51B5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Get Support'),
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

  String _getAppBarTitle() {
    switch(widget.orderStatus) {
      case 'accepted':
        return 'ORDER ACCEPTED';
      case 'reaching':
        return 'REACHING IN 10 MINUTES';
      case 'diagnosing':
        return 'DIAGNOSING';
      case 'repairing':
        return 'REPAIRING';
      case 'completed':
        return 'SERVICE COMPLETED';
      default:
        return 'ORDER DETAILS';
    }
  }

  Widget _buildStatusToggle(String label, bool value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Switch(
            value: value,
            onChanged: (newValue) {
              setState(() {
                if (label == 'Reached') reached = newValue;
                else if (label == 'DIAGNOSED') diagnosed = newValue;
                else if (label == 'REPAIRED') repaired = newValue;
              });
            },
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptedView() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Center(
        child: Text('Map View'),
      ),
    );
  }

  Widget _buildReachingView() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Center(
        child: Text('Map View with ETA'),
      ),
    );
  }

  Widget _buildDiagnosingView() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Center(
        child: Image.asset('assets/diagnosing_illustration.png'),
      ),
    );
  }

  Widget _buildRepairingView() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      child: Center(
        child: Image.asset('assets/repairing_illustration.png'),
      ),
    );
  }

  Widget _buildCompletedView() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const Text(
            'FIXIFY',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}