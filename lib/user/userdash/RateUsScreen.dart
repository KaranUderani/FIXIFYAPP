import 'package:flutter/material.dart';

class RateUsScreen extends StatefulWidget {
  @override
  _RateUsScreenState createState() => _RateUsScreenState();
}

class _RateUsScreenState extends State<RateUsScreen> {
  double rating = 3; // Default rating

  void _submitRating() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Thank You!"),
          content: Text("You rated us $rating stars!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.popUntil(context, (route) => route.isFirst); // Navigate to home screen
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5FF),
      appBar: AppBar(
        title: Text("Rate Us", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "How would you rate our app?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              // Star Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.orange,
                      size: 40,
                    ),
                    onPressed: () {
                      setState(() {
                        rating = index + 1.0;
                      });
                    },
                  );
                }),
              ),
              SizedBox(height: 20),

              // Rating Slider
              Slider(
                value: rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: "$rating",
                activeColor: Colors.orange,
                onChanged: (value) {
                  setState(() {
                    rating = value;
                  });
                },
              ),
              SizedBox(height: 30),

              // Submit Button
              ElevatedButton(
                onPressed: _submitRating,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  backgroundColor: Colors.blue,
                ),
                child: Text("Submit", style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}