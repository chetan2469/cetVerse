import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // For Date Picker
import 'package:cet_verse/PhoneAuthScreen.dart';

class RegisterNewUserScreen extends StatefulWidget {
  @override
  _RegisterNewUserScreenState createState() => _RegisterNewUserScreenState();
}

class _RegisterNewUserScreenState extends State<RegisterNewUserScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String? _educationLevel;
  String? _board;
  final TextEditingController _schoolController = TextEditingController();

  bool _isLoading = false;
  bool _isVerified = false;
  String? _otpSessionId;
  String? _errorMessage;
  bool isNumberValid = false;

  final String apiKey = 'a377dfe4-53ca-11ef-8b60-0200cd936042';
  final String otpTemplateName = 'OTP1';

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
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
      trailing: IconButton(
          onPressed: () {
            refresh();
          },
          icon: Icon(Icons.refresh)),
    );
  }

  void refresh() {
    setState(() {
      _isLoading = false;
      _isVerified = false;
      isNumberValid = false;
      _phoneController.text = '';
      _otpController.text = '';
      _nameController.text = '';
      _cityController.text = '';
      _dobController.text = '';
    });
  }

  Widget _buildInputField(
      TextEditingController controller, String label, IconData icon,
      {int maxLength = 50}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blueGrey),
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType:
            label.contains('Number') ? TextInputType.phone : TextInputType.text,
      ),
    );
  }

  /// 📌 **Mobile Number + Send OTP Button (Single Row)**

  Widget _buildMobileWithOTP(
      BuildContext context, TextEditingController phoneController) {
    return Row(
      children: [
        // Mobile Number Input Field
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
            //    maxLength: 10,
            onChanged: (value) {
              setState(() {
                isNumberValid = value.length == 10;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        // Verify Button (Same Height as TextField)
        SizedBox(
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              backgroundColor: isNumberValid
                  ? _isVerified
                      ? Colors.green
                      : Colors.blue
                  : Colors.grey, // Disable if not valid
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: isNumberValid
                ? () => {
                      if (_isVerified)
                        {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Already Verified '),
                                duration: Duration(seconds: 2)),
                          )
                        }
                      else
                        {sendOTP(context, phoneController.text)}
                    }
                : null, // Disable button if not valid
            child: Text(
              _isVerified ? 'Verified' : 'Verify',
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  void _showOTPDialog(BuildContext context) {
    List<TextEditingController> otpControllers =
        List.generate(6, (index) => TextEditingController());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter OTP'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              6,
              (index) => Container(
                width: 40,
                height: 50,
                margin: EdgeInsets.all(2),
                child: TextField(
                  controller: otpControllers[index],
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    counterText: "",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 5) {
                      FocusScope.of(context).nextFocus(); // Move to next box
                    }
                  },
                  onSubmitted: (value) {
                    if (index == 5) {
                      _verifyOTP(value);
                    }
                  },
                  onEditingComplete: () {
                    if (index == 5) {
                      /// _verifyOTP(value);
                    }
                  },
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String otpEntered = otpControllers.map((c) => c.text).join();
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

  /// 📌 **DOB & City in a Single Row**
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

  /// 📌 **Education Level & Board in a Single Row**
  Widget _buildEducationAndBoardRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: _educationLevel,
            decoration: InputDecoration(
              labelText: 'Education Level',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: ['10th', '12th', 'Graduate'].map((level) {
              return DropdownMenuItem(value: level, child: Text(level));
            }).toList(),
            onChanged: (value) => setState(() => _educationLevel = value),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: _board,
            decoration: InputDecoration(
              labelText: 'Board',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: ['CBSE', 'ICSE', 'State Board'].map((board) {
              return DropdownMenuItem(value: board, child: Text(board));
            }).toList(),
            onChanged: (value) => setState(() => _board = value),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _registerUser,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: const Center(
        child: Text('Register',
            style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }

  Widget _buildLoginOption() {
    return Center(
      child: TextButton(
        onPressed: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => PhoneAuthScreen()),
          );
        },
        child: const Text('Already have an account? Login',
            style: TextStyle(fontSize: 16, color: Colors.blue)),
      ),
    );
  }

  void _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _dobController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  void _checkPhoneNumberAndSendOTP() {
    // Implement OTP logic here
  }

  Future<void> _verifyOTP(String otpEntered) async {
    if (_otpSessionId == null) {
      setState(() {
        _errorMessage = 'OTP session ID is null. Please request OTP again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://2factor.in/API/V1/$apiKey/SMS/VERIFY/$_otpSessionId/$otpEntered'),
      );

      final responseData = json.decode(response.body);

      if (responseData['Status'] == 'Success') {
        setState(() {
          _isVerified = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('OTP Verified Successfully!'),
              duration: Duration(seconds: 2)),
        );
      } else {
        setState(() {
          _errorMessage = 'OTP verification failed. Please try again.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('OTP verification failed. Please try again.'),
              duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error verifying OTP: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> sendOTP(BuildContext context, String phoneNumber) async {
    try {
      // Show snackbar to indicate OTP is being sent
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sending OTP to $phoneNumber...'),
          duration: const Duration(seconds: 2),
        ),
      );

      // API Call to send OTP
      final response = await http.get(
        Uri.parse(
            'https://2factor.in/API/V1/$apiKey/SMS/$phoneNumber/AUTOGEN/$otpTemplateName'),
      );

      // Print raw API response for debugging
      print('API Response Status Code: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      final responseData = json.decode(response.body);

      if (responseData['Status'] == 'Success') {
        setState(() {
          _otpSessionId = responseData['Details'];
          _isLoading = false;
        });

        // Show snackbar confirmation that OTP is sent
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP sent successfully to $phoneNumber'),
            duration: const Duration(seconds: 2),
          ),
        );

        // Show OTP Popup after 1 second delay
        Future.delayed(const Duration(seconds: 1), () {
          _showOTPDialog(context);
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to send OTP. Error: ${responseData['Details']}';
          _isLoading = false;
        });

        // Print error message
        print('OTP API Error: ${responseData['Details']}');

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error sending OTP: $e';
        _isLoading = false;
      });

      // Print the exception
      print('Exception Occurred: $e');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _registerUser() async {
    // Check if OTP is verified before proceeding
    if (!_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify OTP before registration'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Get user details
    String mobileNumber = _phoneController.text.trim();
    String fullName = _nameController.text.trim();
    String dob = _dobController.text.trim();
    String city = _cityController.text.trim();
    String educationLevel = _educationLevel ?? '';
    String board = _board ?? '';
    String school = _schoolController.text.trim();

    // ✅ **Validations for each field**
    if (fullName.isEmpty || fullName.length < 6 || !fullName.contains(" ")) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please enter full name with at least 6 characters and a space.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (dob.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your Date of Birth.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your City.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (school.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your School/College name.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Show loading indicator
    setState(() {
      _isLoading = true;
    });

    try {
      // Store user details in Firestore (users collection, using mobile number as ID)
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
        'createdAt': FieldValue.serverTimestamp(), // Store timestamp
        'userType': "student"
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration Successful!'),
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to PhoneAuthScreen (or Dashboard if required)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => PhoneAuthScreen()),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error registering user: $e'),
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }
}
