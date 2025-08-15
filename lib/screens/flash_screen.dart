import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:get_phone_number/get_phone_number.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/screens/dashboard_page.dart';
import 'package:cet_verse/core/auth/phone_auth_screen.dart';

class FlashScreen extends StatefulWidget {
  const FlashScreen({super.key});

  @override
  _FlashScreenState createState() => _FlashScreenState();
}

class _FlashScreenState extends State<FlashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late Timer _timer;
  final List<String> _slideImages = [
    'assets/stude1.jpg',
    'assets/stude2.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _checkUserLogin();
    // Auto-scroll slides every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < _slideImages.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> _checkUserLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.restoreSession(); // Restore cached session

    if (authProvider.currentUser != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => DashboardPage()),
      );
      return;
    }

    try {
      // Get device's phone number
      String? phoneNumber = await GetPhoneNumber().get();
      phoneNumber = phoneNumber?.replaceAll("91", "").trim();
      phoneNumber = phoneNumber?.replaceAll("+", "").trim();
      print("Detected Mobile Number: $phoneNumber");

      // Check if user exists in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .get();

      if (userDoc.exists) {
        // User exists → Fetch data and navigate to Dashboard
        await authProvider.fetchUserData(phoneNumber!);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => DashboardPage()),
        );
        return;
      }
    } catch (e) {
      print("Error fetching phone number: $e");
    }

    // If number not found or user doesn't exist → Go to PhoneAuthScreen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const PhoneAuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/cetverse.png',
              width: 250,
              height: 250,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 30),

            // Image Slider
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slideImages.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        _slideImages[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(
                _slideImages.length,
                (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.black
                        : Colors.grey.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
