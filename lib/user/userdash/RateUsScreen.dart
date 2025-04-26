import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RateUsScreen extends StatefulWidget {
  const RateUsScreen({Key? key}) : super(key: key);

  @override
  _RateUsScreenState createState() => _RateUsScreenState();
}

class _RateUsScreenState extends State<RateUsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  double _rating = 0;
  bool _isSubmitting = false;
  bool _hasRated = false;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkPreviousRating();
  }

  Future<void> _checkPreviousRating() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String phoneNumber = currentUser.phoneNumber ?? '';

        if (phoneNumber.isNotEmpty) {
          QuerySnapshot ratingSnapshot = await _firestore
              .collection('customer_ratings')
              .where('customerPhone', isEqualTo: phoneNumber)
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

          if (ratingSnapshot.docs.isNotEmpty) {
            var ratingData = ratingSnapshot.docs.first.data() as Map<String, dynamic>;
            setState(() {
              _rating = (ratingData['rating'] as num).toDouble();
              if (ratingData.containsKey('feedback')) {
                _feedbackController.text = ratingData['feedback'];
              }
              _hasRated = true;
            });
          }
        }
      }
    } catch (e) {
      print('Error checking previous rating: $e');
    }
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        String phoneNumber = currentUser.phoneNumber ?? '';

        if (phoneNumber.isNotEmpty) {
          await _firestore.collection('customer_ratings').add({
            'customerPhone': phoneNumber,
            'rating': _rating,
            'feedback': _feedbackController.text,
            'timestamp': FieldValue.serverTimestamp(),
          });

          setState(() {
            _hasRated = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Thank you for your feedback!')),
          );
        }
      }
    } catch (e) {
      print('Error submitting rating: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting rating. Please try again.')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[100],
      appBar: AppBar(
        backgroundColor: Colors.blue[100],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rate Us',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/imagefixify.png',
                    height: 80,
                  ),
                  SizedBox(height: 20),
                  Text(
                    _hasRated
                        ? 'Thank You for Rating Us!'
                        : 'How would you rate your experience?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 25),
                  RatingBar.builder(
                    initialRating: _rating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: true,
                    itemCount: 5,
                    itemSize: 40,
                    itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      setState(() {
                        _rating = rating;
                      });
                    },
                  ),
                  SizedBox(height: 25),
                  TextField(
                    controller: _feedbackController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Share your feedback (optional)',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent,
                      padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      _hasRated ? 'Update Rating' : 'Submit Rating',
                      style: TextStyle(color: Colors.white, fontSize: 16),
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
}