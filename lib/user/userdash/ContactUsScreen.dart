import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  final String supportEmail = "support@fixifyapp.com";
  final List<String> supportPhones = ["+91 9699522545", "+91 9834832580"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Contact Us"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(Icons.support_agent, size: 80, color: Colors.blue),
            ),
            SizedBox(height: 16),
            Text(
              "Need Help?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              "We're here to assist you! Reach out via email or call us directly.",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 20),

            // Email Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.email, color: Colors.blue),
                title: Text(supportEmail, style: TextStyle(fontSize: 16)),
                trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
                onTap: () => _launchEmail(supportEmail),
              ),
            ),

            SizedBox(height: 12),

            // Phone Cards
            ...supportPhones.map((phone) => Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.phone, color: Colors.green),
                title: Text(phone, style: TextStyle(fontSize: 16)),
                trailing: Icon(Icons.call, size: 22, color: Colors.green),
                onTap: () => _launchPhone(phone),
              ),
            )),

            Spacer(),
            Center(
              child: Text(
                "Fixify Support Team",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      throw 'Could not launch email';
    }
  }

  void _launchPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      throw 'Could not launch phone call';
    }
  }
}
