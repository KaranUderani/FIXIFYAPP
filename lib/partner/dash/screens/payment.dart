/*import 'dart:async';
import 'package:flutter/material.dart';
import 'package:upi_india/upi_india.dart';

void main() {
  runApp(PaymentGatewayApp());
}

class PaymentGatewayApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Payment Gateway',
      home: PaymentPage(),
    );
  }
}

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  List<UpiApp> apps = [];
  late Timer _timer;
  int _start = 600; // 10 minutes (600 seconds)
  bool paymentCancelled = false;

  @override
  void initState() {
    super.initState();
    _fetchUpiApps();
    startTimer();
  }

  void _fetchUpiApps() async {
    apps = await UpiIndia().getAllUpiApps(mandatoryTransactionId: false);
    setState(() {});
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          paymentCancelled = true;
        });
        _timer.cancel();
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get timerText {
    int minutes = _start ~/ 60;
    int seconds = _start % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _startTransaction(UpiApp app) async {
    final UpiResponse response = await UpiIndia().startTransaction(
      app: app,
      receiverUpiId: "receiver@upi",
      receiverName: "Test Receiver",
      transactionRefId: "T123456",
      transactionNote: "Test Payment",
      amount: 1.00,
    );

    // You can check the response and show success/failure dialogs
    print(response.status);

    if (response.status == UpiPaymentStatus.SUCCESS) {
      _timer.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Successful!')),
      );
    } else if (response.status == UpiPaymentStatus.FAILURE) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Failed!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment Cancelled or Pending')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (paymentCancelled) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Payment Cancelled'),
          centerTitle: true,
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 100),
              SizedBox(height: 20),
              Text('Payment Time Expired!', style: TextStyle(fontSize: 22)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Gateway'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time left: $timerText', style: TextStyle(fontSize: 18, color: Colors.red)),
            SizedBox(height: 20),
            Text('Choose UPI App:', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Expanded(
              child: apps.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: apps.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Image.memory(apps[index].icon, height: 40, width: 40),
                    title: Text(apps[index].name),
                    onTap: () => _startTransaction(apps[index]),
                  );
                },
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
                child: Text('Back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/