import 'package:cet_verse/core/auth/phone_auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterNewUserScreen extends StatefulWidget {
  const RegisterNewUserScreen({super.key});

  @override
  State<RegisterNewUserScreen> createState() => _RegisterNewUserScreenState();
}

class _RegisterNewUserScreenState extends State<RegisterNewUserScreen>
    with TickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _educationLevel;
  String? _board;
  bool _isLoading = false;
  bool _isVerified = false;
  String? _otpSessionId;
  String? _errorMessage;
  bool isNumberValid = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // 2Factor config
  final String apiKey = 'a377dfe4-53ca-11ef-8b60-0200cd936042';
  final String otpTemplateName = 'OTP1';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _dobController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: keyboardHeight > 0 ? keyboardHeight + 20 : 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.06,
                          vertical: 20,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeader(screenWidth),
                              SizedBox(height: screenHeight * 0.03),
                              _buildRegistrationCard(screenWidth),
                              const Spacer(),
                              _buildLoginSection(),
                              SizedBox(height: screenHeight * 0.02),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Color(0xFF374151),
                size: 20,
              ),
            ),
            IconButton(
              onPressed: _refresh,
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.refresh,
                  color: Color(0xFF374151),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          "Create Account",
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.075,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Join CetVerse and start your learning journey",
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.04,
            color: const Color(0xFF6B7280),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationCard(double screenWidth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMobileWithOTP(screenWidth),
            const SizedBox(height: 24),
            _buildInputField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline,
              validator: (value) {
                if (value?.isEmpty ?? true)
                  return 'Please enter your full name';
                if (value!.length < 6)
                  return 'Name must be at least 6 characters';
                if (!value.contains(' ')) return 'Please enter your full name';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildDateField(screenWidth),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField(
                    controller: _cityController,
                    label: 'City',
                    icon: Icons.location_city_outlined,
                    validator: (value) {
                      if (value?.isEmpty ?? true)
                        return 'Please enter your city';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Fixed: Put dropdowns on separate lines instead of Row
            _buildEducationDropdown(screenWidth),
            const SizedBox(height: 20),
            _buildBoardDropdown(screenWidth),
            const SizedBox(height: 20),
            _buildInputField(
              controller: _schoolController,
              label: 'School/College',
              icon: Icons.school_outlined,
              validator: (value) {
                if (value?.isEmpty ?? true)
                  return 'Please enter your school/college';
                return null;
              },
            ),
            const SizedBox(height: 32),
            _buildRegisterButton(screenWidth),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileWithOTP(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Mobile Number",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _phoneController,
                enabled: !_isVerified,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                onChanged: (value) {
                  setState(() => isNumberValid = value.trim().length == 10);
                },
                validator: (value) {
                  if (value?.isEmpty ?? true)
                    return 'Please enter mobile number';
                  if (value!.length != 10) return 'Enter valid 10-digit number';
                  return null;
                },
                decoration: InputDecoration(
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isVerified
                          ? Colors.green[50]
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _isVerified ? Icons.verified : Icons.phone_outlined,
                      color:
                          _isVerified ? Colors.green : const Color(0xFF6B7280),
                      size: 20,
                    ),
                  ),
                  hintText: "Enter your mobile number",
                  hintStyle: GoogleFonts.poppins(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color:
                          _isVerified ? Colors.green : const Color(0xFFE5E7EB),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color:
                          _isVerified ? Colors.green : const Color(0xFF1A1A1A),
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color:
                          _isVerified ? Colors.green : const Color(0xFFE5E7EB),
                    ),
                  ),
                  filled: true,
                  fillColor: _isVerified ? Colors.green[50] : Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isVerified
                      ? [Colors.green, Colors.green[700]!]
                      : isNumberValid
                          ? [const Color(0xFF1A1A1A), const Color(0xFF2D2D2D)]
                          : [Colors.grey[400]!, Colors.grey[500]!],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isNumberValid || _isVerified
                    ? [
                        BoxShadow(
                          color: (_isVerified ? Colors.green : Colors.black)
                              .withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: ElevatedButton(
                onPressed: isNumberValid
                    ? () {
                        if (_isVerified) {
                          _showSuccessMessage('Number already verified!');
                        } else {
                          sendOTP(context, _phoneController.text.trim());
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: Text(
                  _isVerified ? 'Verified' : 'Verify',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6B7280),
                size: 20,
              ),
            ),
            hintText: "Enter your ${label.toLowerCase()}",
            hintStyle: GoogleFonts.poppins(
              color: const Color(0xFF9CA3AF),
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1A1A1A), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Date of Birth",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _dobController,
          readOnly: true,
          onTap: _pickDate,
          validator: (value) {
            if (value?.isEmpty ?? true)
              return 'Please select your date of birth';
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF6B7280),
                size: 20,
              ),
            ),
            hintText: "Select date",
            hintStyle: GoogleFonts.poppins(
              color: const Color(0xFF9CA3AF),
              fontSize: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1A1A1A), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildEducationDropdown(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Education Level",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _educationLevel,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please select education level';
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.school_outlined,
                color: Color(0xFF6B7280),
                size: 20,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1A1A1A), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: ['10th', '12th', 'Graduate']
              .map((level) => DropdownMenuItem(
                    value: level,
                    child: Text(
                      level,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _educationLevel = value),
        ),
      ],
    );
  }

  Widget _buildBoardDropdown(double screenWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Board",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _board,
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Please select board';
            return null;
          },
          decoration: InputDecoration(
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.assignment_outlined,
                color: Color(0xFF6B7280),
                size: 20,
              ),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF1A1A1A), width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          items: ['CBSE', 'ICSE', 'State Board']
              .map((board) => DropdownMenuItem(
                    value: board,
                    child: Text(
                      board,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _board = value),
        ),
      ],
    );
  }

  Widget _buildRegisterButton(double screenWidth) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _registerUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Create Account',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildLoginSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Already have an account? ",
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const PhoneAuthScreen(),
                ),
              );
            },
            child: Text(
              "Sign In",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOTPDialog(BuildContext context) {
    final otpControllers = List.generate(6, (_) => TextEditingController());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security,
                    color: Colors.blue,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Verify Your Number',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code sent to\n+91 ${_phoneController.text}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color.fromARGB(255, 52, 53, 54),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    6,
                    (i) => Container(
                      width: 45,
                      height: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color.fromARGB(255, 65, 66, 67)),
                      ),
                      child: TextField(
                        controller: otpControllers[i],
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          counterText: "",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (v) {
                          if (v.isNotEmpty && i < 5) {
                            FocusScope.of(context).nextFocus();
                          }
                        },
                        onSubmitted: (v) {
                          if (i == 5) {
                            final otpEntered =
                                otpControllers.map((c) => c.text).join();
                            Navigator.of(context).pop();
                            _verifyOTP(otpEntered);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final otpEntered =
                              otpControllers.map((c) => c.text).join();
                          if (otpEntered.length == 6) {
                            Navigator.of(context).pop();
                            _verifyOTP(otpEntered);
                          } else {
                            _showErrorMessage('Please enter complete OTP');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A1A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Verify',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _refresh() {
    setState(() {
      _isLoading = false;
      _isVerified = false;
      isNumberValid = false;
      _phoneController.clear();
      _nameController.clear();
      _cityController.clear();
      _dobController.clear();
      _schoolController.clear();
      _educationLevel = null;
      _board = null;
      _otpSessionId = null;
      _errorMessage = null;
    });
    _showSuccessMessage('Form refreshed successfully');
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005, 1, 1),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A1A1A),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1A1A1A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> _verifyOTP(String otpEntered) async {
    if (_otpSessionId == null) {
      _showErrorMessage('OTP session expired. Please request new OTP.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resp = await http.get(Uri.parse(
          'https://2factor.in/API/V1/$apiKey/SMS/VERIFY/$_otpSessionId/$otpEntered'));
      final data = json.decode(resp.body);

      if (data['Status'] == 'Success') {
        setState(() => _isVerified = true);
        if (!mounted) return;
        _showSuccessMessage('Mobile number verified successfully!');
      } else {
        _showErrorMessage('Invalid OTP. Please try again.');
      }
    } catch (e) {
      _showErrorMessage('Error verifying OTP. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> sendOTP(BuildContext context, String phoneNumber) async {
    try {
      _showLoadingMessage('Sending OTP to +91 $phoneNumber...');

      final resp = await http.get(Uri.parse(
          'https://2factor.in/API/V1/$apiKey/SMS/$phoneNumber/AUTOGEN/$otpTemplateName'));

      final data = json.decode(resp.body);

      if (data['Status'] == 'Success') {
        setState(() {
          _otpSessionId = data['Details'];
          _isLoading = false;
        });

        if (!mounted) return;
        _showSuccessMessage('OTP sent successfully to +91 $phoneNumber');

        Future.delayed(
            const Duration(milliseconds: 600), () => _showOTPDialog(context));
      } else {
        _showErrorMessage('Failed to send OTP: ${data['Details']}');
      }
    } catch (e) {
      _showErrorMessage('Error sending OTP. Please try again.');
    }
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorMessage('Please fill all required fields correctly');
      return;
    }

    if (!_isVerified) {
      _showErrorMessage('Please verify your mobile number first');
      return;
    }

    final mobileNumber = _phoneController.text.trim();
    final fullName = _nameController.text.trim();
    final dob = _dobController.text.trim();
    final city = _cityController.text.trim();
    final educationLevel = _educationLevel ?? '';
    final board = _board ?? '';
    final school = _schoolController.text.trim();

    setState(() => _isLoading = true);

    try {
      // Check if user already exists
      final exists = await FirebaseFirestore.instance
          .collection('users')
          .doc(mobileNumber)
          .get();

      if (exists.exists) {
        _showErrorMessage('Mobile number already registered. Please login.');
        setState(() => _isLoading = false);
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(mobileNumber)
          .set({
        'name': fullName,
        'dob': dob,
        'city': city,
        'educationLevel': educationLevel,
        'board': board,
        'school': school,
        'createdAt': FieldValue.serverTimestamp(),
        'userType': "Student",

        // Starter subscription & features
        'subscription': {
          'planType': 'Starter',
          'status': 'active',
          'startDate': FieldValue.serverTimestamp(),
          'endDate': null,
          'paymentMethod': 'none',
          'amountPaid': 0,
        },
        'features': {
          'mhtCetPyqsAccess': 'limited',
          'boardPyqsAccess': false,
          'chapterWiseNotesAccess': false,
          'topperNotesDownload': false,
          'mockTestsPerSubject': 1,
          'fullMockTestSeries': false,
          'topperProfilesAccess': 'read-only',
          'performanceTracking': true,
          'priorityFeatureAccess': false,
        },

        // Stats containers
        'user solve questions': {
          'physics': 0,
          'chemistry': 0,
          'maths': 0,
          'biology': 0
        },
        'total solve questions': {
          'physics': 0,
          'chemistry': 0,
          'maths': 0,
          'biology': 0
        },
      });

      if (!mounted) return;
      _showSuccessMessage('Account created successfully! Please login.');

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const PhoneAuthScreen()));
      });
    } catch (e) {
      _showErrorMessage('Error creating account. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showLoadingMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
