import 'package:flutter/material.dart';

class Bookings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bookings"),
        backgroundColor: Colors.red[300],
      ),
      body: Center(
        child: Text(
          "No Bookings Yet",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ),
    );
  }
}
