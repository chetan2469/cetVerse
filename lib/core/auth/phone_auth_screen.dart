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

class _PhoneAuthScreenState extends State<PhoneAuthScreen>
    with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isOtpMode = true;
  bool _isPasswordVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _getDevicePhoneNumber();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _getDevicePhoneNumber() async {
    try {
      String? phoneNumber = await GetPhoneNumber().get();
      phoneNumber = phoneNumber?.replaceAll("91", "").trim();
      phoneNumber = phoneNumber?.replaceAll("+", "").trim();
      if (mounted) {
        setState(() {
          _phoneController.text = phoneNumber ?? '';
        });
      }
    } catch (e) {
      print("Error fetching phone number: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Container(
          height: screenHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[50]!,
                Colors.indigo[50]!,
                Colors.white,
              ],
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.06,
                    vertical: isSmallScreen ? 20 : 40,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(isSmallScreen),
                        SizedBox(height: isSmallScreen ? 20 : 40),
                        _buildMainCard(authProvider, isSmallScreen),
                        const Spacer(),
                        _buildNewUserButton(),
                        SizedBox(height: isSmallScreen ? 10 : 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Image.asset(
            'assets/cetverse.png',
            height: isSmallScreen ? 50 : 60,
            width: isSmallScreen ? 50 : 60,
          ),
        ),
        SizedBox(height: isSmallScreen ? 15 : 25),
        Text(
          "Welcome Back!",
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 24 : 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isSmallScreen ? 5 : 8),
        Text(
          "Sign in to continue your learning journey",
          style: GoogleFonts.poppins(
            fontSize: isSmallScreen ? 14 : 16,
            color: Colors.black54,
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMainCard(AuthProvider authProvider, bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLoginModeToggle(isSmallScreen),
          SizedBox(height: isSmallScreen ? 20 : 25),
          _buildPhoneInput(authProvider, isSmallScreen),
          if (_isOtpMode && authProvider.isOtpSent) ...[
            SizedBox(height: isSmallScreen ? 16 : 20),
            _buildOtpInput(authProvider, isSmallScreen),
          ],
          if (!_isOtpMode) ...[
            SizedBox(height: isSmallScreen ? 16 : 20),
            _buildPasswordInput(isSmallScreen),
          ],
          SizedBox(height: isSmallScreen ? 25 : 30),
          _buildActionButton(authProvider, isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildLoginModeToggle(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isOtpMode = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 12 : 14,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: _isOtpMode ? Colors.black87 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isOtpMode
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  "Login with OTP",
                  style: GoogleFonts.poppins(
                    color: _isOtpMode ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isOtpMode = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.symmetric(
                  vertical: isSmallScreen ? 12 : 14,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: !_isOtpMode ? Colors.black87 : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_isOtpMode
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  "Login with Password",
                  style: GoogleFonts.poppins(
                    color: !_isOtpMode ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput(AuthProvider authProvider, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        maxLength: 10,
        style: GoogleFonts.poppins(
          fontSize: isSmallScreen ? 15 : 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: 'Mobile Number',
          labelStyle: GoogleFonts.poppins(
            color: Colors.black54,
            fontSize: isSmallScreen ? 14 : 15,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.phone_android, color: Colors.blue, size: 20),
          ),
          prefixStyle: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          counterText: '',
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isSmallScreen ? 16 : 18,
          ),
        ),
      ),
    );
  }

  Widget _buildOtpInput(AuthProvider authProvider, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: isSmallScreen ? 18 : 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 4,
        ),
        decoration: InputDecoration(
          labelText: 'Enter OTP',
          labelStyle: GoogleFonts.poppins(
            color: Colors.black54,
            fontSize: isSmallScreen ? 14 : 15,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.security, color: Colors.green, size: 20),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.green, width: 2),
          ),
          counterText: '',
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isSmallScreen ? 16 : 18,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordInput(bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        style: GoogleFonts.poppins(
          fontSize: isSmallScreen ? 15 : 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: 'Password',
          labelStyle: GoogleFonts.poppins(
            color: Colors.black54,
            fontSize: isSmallScreen ? 14 : 15,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                const Icon(Icons.lock_outline, color: Colors.orange, size: 20),
          ),
          suffixIcon: IconButton(
            onPressed: () =>
                setState(() => _isPasswordVisible = !_isPasswordVisible),
            icon: Icon(
              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
              size: 20,
            ),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.orange, width: 2),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isSmallScreen ? 16 : 18,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(AuthProvider authProvider, bool isSmallScreen) {
    return Container(
      height: isSmallScreen ? 50 : 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Colors.black87, Colors.black54],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: authProvider.isLoading
            ? null
            : () async {
                await _handleAuthentication(authProvider);
              },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: authProvider.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _getButtonText(authProvider),
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 15 : 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildNewUserButton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextButton(
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => RegisterNewUserScreen()),
          );
        },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: RichText(
          text: TextSpan(
            text: "New to CET Verse? ",
            style: GoogleFonts.poppins(
              fontSize: 15,
              color: Colors.black54,
              fontWeight: FontWeight.w400,
            ),
            children: [
              TextSpan(
                text: "Sign Up",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getButtonText(AuthProvider authProvider) {
    if (_isOtpMode) {
      return authProvider.isOtpSent ? 'Verify OTP' : 'Send OTP';
    } else {
      return 'Login with Password';
    }
  }

  Future<void> _handleAuthentication(AuthProvider authProvider) async {
    if (_isOtpMode) {
      if (authProvider.isOtpSent) {
        bool isValid = await authProvider.verifyOTP(
          _phoneController.text.trim(),
          _otpController.text.trim(),
        );
        if (isValid && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => DashboardPage()),
          );
        }
      } else {
        bool userExists =
            await authProvider.checkUserExists(_phoneController.text.trim());
        if (userExists) {
          authProvider.sendOTP(_phoneController.text.trim());
        } else if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => RegisterNewUserScreen()),
          );
        }
      }
    } else {
      bool isValid = await authProvider.loginWithPassword(
        _phoneController.text.trim(),
        _passwordController.text.trim(),
      );
      if (isValid && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => DashboardPage()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid credentials'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
