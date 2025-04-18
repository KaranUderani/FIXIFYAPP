import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({Key? key}) : super(key: key);

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch $url');
    }
  }

  void _copyEmail(BuildContext context) {
    Clipboard.setData(ClipboardData(text: 'teamfixifyapplication@gmail.com'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow[100],
      appBar: AppBar(
        backgroundColor: Colors.yellow[100],
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Contact Us',
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
              padding: EdgeInsets.all(25),
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
                  CircleAvatar(
                    backgroundColor: Colors.yellow[100],
                    radius: 40,
                    child: Image.asset(
                      'assets/images/imagefixify.png',
                      height: 50,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'We\'re here to help!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Our team is available to assist you with any questions or concerns you may have.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 30),
                  _buildContactItem(
                    context,
                    icon: Icons.email_outlined,
                    title: 'Email Us',
                    subtitle: 'teamfixifyapplication@gmail.com',
                    onTap: () => _copyEmail(context),
                    trailingIcon: Icons.copy,
                  ),
                  Divider(height: 30),
                  _buildContactItem(
                    context,
                    icon: Icons.phone_outlined,
                    title: 'Call Us',
                    subtitle: '+91 9834832580',
                    onTap: () => _launchUrl('tel:+919834832580'),
                    trailingIcon: Icons.call,
                  ),
                  Divider(height: 30),
                  _buildContactItem(
                    context,
                    icon: Icons.chat_bubble_outline,
                    title: 'WhatsApp',
                    subtitle: '+91 9834832580',
                    onTap: () => _launchUrl('https://wa.me/919834832580'),
                    trailingIcon: Icons.open_in_new,
                  ),
                  Divider(height: 30),
                  _buildContactItem(
                    context,
                    icon: Icons.location_on_outlined,
                    title: 'Visit Us',
                    subtitle: 'Fixify HQ, Mumbai, India',
                    onTap: () => _launchUrl('https://maps.app.goo.gl/ArtKWWQh1P8R188e7'),
                    trailingIcon: Icons.directions,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    'Connect with us on social media',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSocialButton(
                        icon: Icons.facebook,
                        color: Colors.blue[900]!,
                        onTap: () => _launchUrl('https://facebook.com'),
                      ),
                      _buildSocialButton(
                        icon: Icons.camera_alt,
                        color: Colors.purple,
                        onTap: () => _launchUrl('https://instagram.com'),
                      ),
                      _buildSocialButton(
                        icon: Icons.add_link,
                        color: Colors.teal,
                        onTap: () => _launchUrl('https://karanuderani60776.wixsite.com/fixify'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
        required IconData trailingIcon,
      }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.blue[800]),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(trailingIcon, color: Colors.blue[800]),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
    );
  }
}