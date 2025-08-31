import 'package:cet_verse/core/auth/phone_auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class RegisterNewUserScreen extends StatefulWidget {
  const RegisterNewUserScreen({super.key});

  @override
  State<RegisterNewUserScreen> createState() => _RegisterNewUserScreenState();
}

class _RegisterNewUserScreenState extends State<RegisterNewUserScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();

  String? _educationLevel;
  String? _board;

  bool _isLoading = false;
  bool _isVerified = false;
  String? _otpSessionId;
  String? _errorMessage;
  bool isNumberValid = false;

  // 2Factor config
  final String apiKey = 'a377dfe4-53ca-11ef-8b60-0200cd936042';
  final String otpTemplateName = 'OTP1';

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _dobController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildMobileWithOTP(context, _phoneController),
                const SizedBox(height: 12),
                _buildInputField(_nameController, 'Full Name', Icons.person),
                const SizedBox(height: 12),
                _buildDobAndCityRow(),
                const SizedBox(height: 12),
                _buildEducationAndBoardRow(),
                const SizedBox(height: 12),
                _buildInputField(
                    _schoolController, 'School/College', Icons.school),
                const SizedBox(height: 20),
                _buildRegisterButton(),
                const SizedBox(height: 10),
                _buildLoginOption(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // UI bits
  Widget _buildHeader() {
    return ListTile(
      title: const Text(
        "Create new Account",
        style: TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
      ),
      subtitle: Text(
        "Fill in the details to register",
        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
      ),
      trailing:
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
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
  }

  Widget _buildInputField(
      TextEditingController controller, String label, IconData icon) {
    final isPhone = label.contains('Number');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blueGrey),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      ),
    );
  }

  Widget _buildMobileWithOTP(
      BuildContext context, TextEditingController phoneController) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            enabled: !_isVerified,
            controller: phoneController,
            decoration: InputDecoration(
              labelText: 'Mobile Number',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.phone,
            onChanged: (value) {
              // Basic 10-digit validation; tweak if you want stricter (e.g., starts 6-9)
              setState(() => isNumberValid = value.trim().length == 10);
            },
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: isNumberValid
                  ? (_isVerified ? Colors.green : Colors.blue)
                  : Colors.grey,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: isNumberValid
                ? () {
                    if (_isVerified) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Already Verified'),
                            duration: Duration(seconds: 2)),
                      );
                    } else {
                      sendOTP(context, phoneController.text.trim());
                    }
                  }
                : null,
            child: Text(_isVerified ? 'Verified' : 'Verify',
                style: const TextStyle(fontSize: 16, color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildDobAndCityRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextField(
            controller: _dobController,
            readOnly: true,
            onTap: _pickDate,
            decoration: InputDecoration(
              prefixIcon:
                  const Icon(Icons.calendar_today, color: Colors.blueGrey),
              labelText: 'Date of Birth',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: _buildInputField(_cityController, 'City', Icons.location_city),
        ),
      ],
    );
  }

  Widget _buildEducationAndBoardRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            initialValue: _educationLevel,
            decoration: InputDecoration(
              labelText: 'Education Level',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const ['10th', '12th', 'Graduate']
                .map((level) =>
                    DropdownMenuItem(value: level, child: Text(level)))
                .toList(),
            onChanged: (value) => setState(() => _educationLevel = value),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            initialValue: _board,
            decoration: InputDecoration(
              labelText: 'Board',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: const ['CBSE', 'ICSE', 'State Board']
                .map((board) =>
                    DropdownMenuItem(value: board, child: Text(board)))
                .toList(),
            onChanged: (value) => setState(() => _board = value),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _registerUser,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Center(
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Text('Register',
                style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }

  Widget _buildLoginOption() {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const PhoneAuthScreen()));
        },
        child: const Text('Already have an account? Login',
            style: TextStyle(fontSize: 16, color: Colors.blue)),
      ),
    );
  }

  // OTP dialog
  void _showOTPDialog(BuildContext context) {
    final otpControllers = List.generate(6, (_) => TextEditingController());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter OTP'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              6,
              (i) => Container(
                width: 40,
                height: 50,
                margin: const EdgeInsets.all(2),
                child: TextField(
                  controller: otpControllers[i],
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    counterText: "",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
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
                      _verifyOTP(otpEntered);
                    }
                  },
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final otpEntered = otpControllers.map((c) => c.text).join();
                if (otpEntered.length == 6) {
                  Navigator.of(context).pop();
                  _verifyOTP(otpEntered);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter a 6-digit OTP'),
                        duration: Duration(seconds: 2)),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  // Helpers
  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005, 1, 1),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> _verifyOTP(String otpEntered) async {
    if (_otpSessionId == null) {
      setState(() =>
          _errorMessage = 'OTP session ID is null. Please request OTP again.');
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('OTP Verified Successfully!'),
              duration: Duration(seconds: 2)),
        );
      } else {
        setState(
            () => _errorMessage = 'OTP verification failed. Please try again.');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('OTP verification failed. Please try again.'),
              duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error verifying OTP: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> sendOTP(BuildContext context, String phoneNumber) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Sending OTP to $phoneNumber...'),
            duration: const Duration(seconds: 2)),
      );

      final resp = await http.get(Uri.parse(
          'https://2factor.in/API/V1/$apiKey/SMS/$phoneNumber/AUTOGEN/$otpTemplateName'));

      final data = json.decode(resp.body);

      if (data['Status'] == 'Success') {
        setState(() {
          _otpSessionId = data['Details'];
          _isLoading = false;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('OTP sent successfully to $phoneNumber'),
              duration: const Duration(seconds: 2)),
        );

        Future.delayed(
            const Duration(milliseconds: 600), () => _showOTPDialog(context));
      } else {
        setState(() {
          _errorMessage = 'Failed to send OTP. Error: ${data['Details']}';
          _isLoading = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(_errorMessage!),
              duration: const Duration(seconds: 3)),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sending OTP: $e';
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_errorMessage!),
            duration: const Duration(seconds: 3)),
      );
    }
  }

  Future<void> _registerUser() async {
    if (!_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please verify OTP before registration'),
            duration: Duration(seconds: 2)),
      );
      return;
    }

    final mobileNumber = _phoneController.text.trim();
    final fullName = _nameController.text.trim();
    final dob = _dobController.text.trim();
    final city = _cityController.text.trim();
    final educationLevel = _educationLevel ?? '';
    final board = _board ?? '';
    final school = _schoolController.text.trim();

    if (fullName.isEmpty || fullName.length < 6 || !fullName.contains(" ")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please enter full name with at least 6 characters and a space.'),
            duration: Duration(seconds: 2)),
      );
      return;
    }
    if (dob.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter your Date of Birth.'),
            duration: Duration(seconds: 2)),
      );
      return;
    }
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter your City.'),
            duration: Duration(seconds: 2)),
      );
      return;
    }
    if (school.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter your School/College name.'),
            duration: Duration(seconds: 2)),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Prevent duplicate registration
      final exists = await FirebaseFirestore.instance
          .collection('users')
          .doc(mobileNumber)
          .get();
      if (exists.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Mobile already registered. Please login.'),
              duration: Duration(seconds: 2)),
        );
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

        // ---- Starter subscription & features ----
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
          'mockTestsPerSubject': 1, // Starter rule
          'fullMockTestSeries': false,
          'topperProfilesAccess': 'read-only',
          'performanceTracking': true, // Starter rule
          'priorityFeatureAccess': false,
        },

        // ---- stats containers ----
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Registration Successful!'),
            duration: Duration(seconds: 2)),
      );

      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PhoneAuthScreen()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error registering user: $e'),
            duration: const Duration(seconds: 5)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
