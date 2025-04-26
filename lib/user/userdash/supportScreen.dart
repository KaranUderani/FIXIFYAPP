import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  _SupportScreenState createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final TextEditingController _queryController = TextEditingController();
  final List<Map<String, dynamic>> _faqs = [
    {
      'question': 'How do I get verified on Fixify Partner?',
      'answer': 'To get verified, go to your Profile page, tap on "Edit Profile" and then "Verify Now". Upload a valid government ID or address proof to complete verification.'
    },
    {
      'question': 'When will I receive payment for my services?',
      'answer': 'Payments are processed within 24-48 hours after service completion and customer confirmation once processed they get deposited in your wallet can withdraw from payments section.'
    },
    {
      'question': 'How can I update my service area?',
      'answer': 'You can update your service area from the Home screen by tapping on "Service Area" and selecting your preferred locations.'
    },
    {
      'question': 'What happens if I cancel a booking?',
      'answer': 'Cancellations may affect your partner rating. If you need to cancel, please do so at least 4 hours before the scheduled time to minimize impact.'
    },
    {
      'question': 'How do I contact customer support?',
      'answer': 'You can reach our customer support team through the Contact Us section or by emailing support@fixify.com.'
    },
  ];

  bool _isSubmitting = false;

  Future<void> _submitQuery() async {
    if (_queryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your query')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });


    try {
      final user = FirebaseAuth.instance.currentUser;
      final phoneNumber = user?.phoneNumber ?? 'Unknown';

      await FirebaseFirestore.instance.collection('customer_support_queries').add({
        'query': _queryController.text,
        'phone': phoneNumber,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _isSubmitting = false;
        _queryController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your query has been submitted. We\'ll get back to you soon.'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error submitting query: $e');
      // Show more specific error info
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit query. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          'Support',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search and submit section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need Help?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Submit your query and our support team will get back to you within 24 hours.',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _queryController,
                      decoration: InputDecoration(
                        hintText: 'Type your question here...',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () => _queryController.clear(),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitQuery,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSubmitting
                            ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                            : Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // FAQ section
            Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _faqs.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(
                        _faqs[index]['question'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _faqs[index]['answer'],
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      // Add a direct contact button in the bottom right
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.greenAccent,
        child: Icon(Icons.chat),
        onPressed: () {
          // Show live chat or direct contact options
          showModalBottomSheet(
            context: context,
            isScrollControlled: true, // This prevents overflow
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => SingleChildScrollView( // Makes content scrollable
              child: Container(
                // Fixed: Combine both padding definitions into one
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Only take necessary space
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Us',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      leading: Icon(Icons.email, color: Colors.purple),
                      title: Text('Email Support'),
                      subtitle: Text('teamfixifyapplication@gmail.com'),
                      onTap: () {
                        // Launch email
                        launch('mailto:teamfixifyapplication@gmail.com');
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.phone, color: Colors.purple),
                      title: Text('Call Support'),
                      subtitle: Text('Available 9 AM - 6 PM'),
                      onTap: () {
                        // Launch phone call
                        launch('tel:+919834832580'); // Replace with your support number
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}