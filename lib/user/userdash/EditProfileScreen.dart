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

  // Define theme colors
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color secondaryBlue = Color(0xFF64B5F6);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color accentYellow = Color(0xFFFFD54F);
  static const Color backgroundWhite = Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
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
      backgroundColor: backgroundWhite,
      appBar: AppBar(
        title: Text(
          "Edit Profile",
          style: TextStyle(
            color: Color(0xFF263238),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryBlue),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: primaryBlue),
            onPressed: () {
              // Show help dialog
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, backgroundWhite],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: accentYellow, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 65,
                        backgroundColor: lightBlue,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : AssetImage("assets/images/imagefixify.png") as ImageProvider,
                      ),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [primaryBlue, secondaryBlue],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 5,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 25),

                // Profile Form Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Title
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: accentYellow,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "PERSONAL INFORMATION",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF455A64),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Full Name
                      _buildTextField(_nameController, "Full Name", Icons.person_outline, TextInputType.name),
                      SizedBox(height: 18),

                      // Email
                      _buildTextField(
                        _emailController,
                        "Email",
                        Icons.email_outlined,
                        TextInputType.emailAddress,
                        onChanged: (value) {
                          if (value != widget.email) {
                            setState(() {
                              _emailChanged = true;
                              _isEmailVerified = false;
                            });
                          } else {
                            setState(() {
                              _emailChanged = false;
                            });
                          }
                        },
                        showStatus: _emailChanged,
                        isVerified: _isEmailVerified,
                      ),
                      if (_emailChanged && !_isEmailVerified)
                        _buildVerificationButton("Verify Email", () => _sendOTP("email")),
                      SizedBox(height: 18),

                      // Phone Number
                      _buildTextField(
                        _phoneController,
                        "Mobile Number",
                        Icons.phone_outlined,
                        TextInputType.phone,
                        onChanged: (value) {
                          if (value != widget.phone) {
                            setState(() {
                              _phoneChanged = true;
                              _isPhoneVerified = false;
                            });
                          } else {
                            setState(() {
                              _phoneChanged = false;
                            });
                          }
                        },
                        showStatus: _phoneChanged,
                        isVerified: _isPhoneVerified,
                      ),
                      if (_phoneChanged && !_isPhoneVerified)
                        _buildVerificationButton("Verify Phone", () => _sendOTP("phone")),
                    ],
                  ),
                ),
                SizedBox(height: 30),

                // Save Changes Button
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate() &&
                          (!_emailChanged || _isEmailVerified) &&
                          (!_phoneChanged || _isPhoneVerified)) {
                        Navigator.pop(context, {
                          "name": _nameController.text,
                          "email": _emailController.text,
                          "phone": _phoneController.text,
                        });
                      } else if (!_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Please fill all required fields"),
                            backgroundColor: Colors.red.shade400,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Please verify changed contact information"),
                            backgroundColor: Colors.orange.shade700,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 5,
                    ),
                    child: Text(
                      "Save Changes",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15),

                // Cancel Button
                Container(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: primaryBlue.withOpacity(0.5)),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: primaryBlue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced Text Field Widget
  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon,
      TextInputType inputType, {
        Function(String)? onChanged,
        bool showStatus = false,
        bool isVerified = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF455A64),
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: inputType,
            onChanged: onChanged,
            style: TextStyle(fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: primaryBlue, size: 22),
              suffixIcon: showStatus
                  ? Icon(
                isVerified ? Icons.check_circle : Icons.info_outline,
                color: isVerified ? Colors.green : accentYellow,
              )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryBlue, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter your $label";
              }

              if (label == "Email" && !value.contains('@')) {
                return "Please enter a valid email address";
              }

              if (label == "Mobile Number" && value.length < 10) {
                return "Please enter a valid phone number";
              }

              return null;
            },
          ),
        ),
        if (showStatus && !isVerified)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 8),
            child: Text(
              "Verification required",
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  // Enhanced OTP Verification Button
  Widget _buildVerificationButton(String text, VoidCallback onPressed) {
    return Padding(
      padding: EdgeInsets.only(top: 2, bottom: 6),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user_outlined, size: 16),
            SizedBox(width: 6),
            Text(text),
          ],
        ),
      ),
    );
  }
}