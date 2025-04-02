import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:get_phone_number/get_phone_number.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cet_verse/state/AuthProvider.dart';
import 'package:cet_verse/DashboardPage.dart';
import 'package:cet_verse/PhoneAuthScreen.dart';

class FlashScreen extends StatefulWidget {
  const FlashScreen({super.key});

  @override
  _FlashScreenState createState() => _FlashScreenState();
}

class _FlashScreenState extends State<FlashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserLogin();
  }

  Future<void> _checkUserLogin() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Get device's phone number
      String? phoneNumber = await GetPhoneNumber().get();

      if (phoneNumber != null) {
        phoneNumber =
            phoneNumber.replaceAll("91", "").trim(); // Remove country code
        phoneNumber =
            phoneNumber.replaceAll("+", "").trim(); // Remove country code
        print("Detected Mobile Number: $phoneNumber");

        // Check if user exists in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(phoneNumber)
            .get();

        if (userDoc.exists) {
          // User exists → Fetch data and navigate to Dashboard
          await authProvider.fetchUserData(phoneNumber);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => DashboardPage()),
          );
          return;
        }
      }
    } catch (e) {
      print("Error fetching phone number: $e");
    }

    // If number not found or user doesn’t exist → Go to PhoneAuthScreen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const PhoneAuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Clean white background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/cetverse.png', // App logo
              width: 250,
              height: 250,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              strokeWidth: 2.5,
            ),
          ],
        ),
      ),
    );
  }
}
