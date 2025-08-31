import 'package:cet_verse/core/auth/register_new_user_screen.dart';
import 'package:cet_verse/screens/dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_phone_number/get_phone_number.dart';
import 'package:cet_verse/core/auth/AuthProvider.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isOtpMode = true; // Toggle between OTP and Password modes

  @override
  void initState() {
    super.initState();
    _getDevicePhoneNumber();
  }

  /// **Fetch and set the device's mobile number**
  Future<void> _getDevicePhoneNumber() async {
    try {
      String? phoneNumber = await GetPhoneNumber().get();
      phoneNumber = phoneNumber.replaceAll("91", "").trim();
      phoneNumber = phoneNumber.replaceAll("+", "").trim();
      setState(() {
        _phoneController.text = phoneNumber ?? '';
      });
    } catch (e) {
      print("Error fetching phone number: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 50),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildLoginModeToggle(),
              const SizedBox(height: 20),
              _buildPhoneInput(authProvider),
              if (_isOtpMode && authProvider.isOtpSent)
                Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildOtpInput(authProvider),
                  ],
                ),
              if (!_isOtpMode)
                Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildPasswordInput(),
                  ],
                ),
              const SizedBox(height: 30),
              _buildActionButton(authProvider),
              const SizedBox(height: 20),
              _buildNewUserButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// **📌 Header Section**
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset('assets/cetverse.png', height: 80), // App logo
        const SizedBox(height: 10),
        Text(
          "Welcome Back!.",
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "Login with your mobile number",
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  /// **📌 Login Mode Toggle**
  Widget _buildLoginModeToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => setState(() => _isOtpMode = true),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isOtpMode ? Colors.black : Colors.grey,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text("Login with OTP",
              style: GoogleFonts.poppins(color: Colors.white)),
        ),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () => setState(() => _isOtpMode = false),
          style: ElevatedButton.styleFrom(
            backgroundColor: !_isOtpMode ? Colors.black : Colors.grey,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text("Login with Password",
              style: GoogleFonts.poppins(color: Colors.white)),
        ),
      ],
    );
  }

  /// **📌 Mobile Number Input Field (Auto-filled and Editable)**
  Widget _buildPhoneInput(AuthProvider authProvider) {
    return TextField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      decoration: InputDecoration(
        labelText: 'Mobile Number',
        prefixIcon: const Icon(Icons.phone, color: Colors.black54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// **📌 OTP Input Field**
  Widget _buildOtpInput(AuthProvider authProvider) {
    return TextField(
      controller: _otpController,
      keyboardType: TextInputType.number,
      maxLength: 6,
      decoration: InputDecoration(
        labelText: 'Enter OTP',
        prefixIcon: const Icon(Icons.lock, color: Colors.black54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// **📌 Password Input Field**
  Widget _buildPasswordInput() {
    return TextField(
      controller: _passwordController,
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock, color: Colors.black54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// **📌 Action Button (Send OTP / Verify OTP / Login with Password)**
  Widget _buildActionButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (_isOtpMode) {
            if (authProvider.isOtpSent) {
              bool isValid = await authProvider.verifyOTP(
                  _phoneController.text.trim(), _otpController.text.trim());
              if (isValid) {
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => DashboardPage()));
              }
            } else {
              bool userExists = await authProvider
                  .checkUserExists(_phoneController.text.trim());
              if (userExists) {
                authProvider.sendOTP(_phoneController.text.trim());
              } else {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => RegisterNewUserScreen()));
              }
            }
          } else {
            bool isValid = await authProvider.loginWithPassword(
                _phoneController.text.trim(), _passwordController.text.trim());
            if (isValid) {
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => DashboardPage()));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid credentials')));
            }
          }
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: authProvider.isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                _isOtpMode
                    ? (authProvider.isOtpSent ? 'Verify OTP' : 'Send OTP')
                    : 'Login with Password',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
      ),
    );
  }

  /// **📌 New User? Sign Up Button**
  Widget _buildNewUserButton() {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => RegisterNewUserScreen()));
        },
        child: Text(
          "New User? Sign Up",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
