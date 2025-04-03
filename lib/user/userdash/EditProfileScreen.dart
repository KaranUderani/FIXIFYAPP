import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'OTPVerificationScreen.dart';
import 'string_extensions.dart';

class EditProfileScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phone;

  EditProfileScreen({required this.name, required this.email, required this.phone});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  File? _profileImage;

  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;
  bool _emailChanged = false;
  bool _phoneChanged = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  void _sendOTP(String type) async {
    final bool isVerified = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OTPVerificationScreen(type: type.capitalize()),
      ),
    );

    setState(() {
      if (type == "email") {
        _isEmailVerified = isVerified;
      } else {
        _isPhoneVerified = isVerified;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Edit Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Image
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 65,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : AssetImage("assets/images/imagefixify.png") as ImageProvider,
                  ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),

              // Full Name
              _buildTextField(_nameController, "Full Name", Icons.person, TextInputType.name),
              SizedBox(height: 15),

              // Email
              _buildTextField(
                _emailController,
                "Email",
                Icons.email,
                TextInputType.emailAddress,
                onChanged: (value) {
                  if (value != widget.email) {
                    setState(() {
                      _emailChanged = true;
                      _isEmailVerified = false;
                    });
                  }
                },
              ),
              if (_emailChanged && !_isEmailVerified)
                _buildVerificationButton("Verify Email", () => _sendOTP("email")),
              SizedBox(height: 15),

              // Phone Number
              _buildTextField(
                _phoneController,
                "Mobile Number",
                Icons.phone,
                TextInputType.phone,
                onChanged: (value) {
                  if (value != widget.phone) {
                    setState(() {
                      _phoneChanged = true;
                      _isPhoneVerified = false;
                    });
                  }
                },
              ),
              if (_phoneChanged && !_isPhoneVerified)
                _buildVerificationButton("Verify Phone", () => _sendOTP("phone")),
              SizedBox(height: 30),

              // Save Changes Button
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      (!_emailChanged || _isEmailVerified) &&
                      (!_phoneChanged || _isPhoneVerified)) {
                    Navigator.pop(context, {
                      "name": _nameController.text,
                      "email": _emailController.text,
                      "phone": _phoneController.text,
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Please verify email and phone before saving.")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text("Save Changes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Text Field Widget
  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon,
      TextInputType inputType, {
        Function(String)? onChanged,
      }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return "Please enter your $label";
        return null;
      },
    );
  }

  // OTP Verification Button
  Widget _buildVerificationButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Colors.blue,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        child: Text(text),
      ),
    );
  }
}
