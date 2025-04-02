import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/UserModel.dart';

class AuthProvider with ChangeNotifier {
  final String apiKey = 'a377dfe4-53ca-11ef-8b60-0200cd936042';
  final String otpTemplateName = 'OTP1';

  bool isLoading = false;
  bool isOtpSent = false;
  String? otpSessionId;
  String? errorMessage, userPhoneNumber;
  UserModel? currentUser; // Store logged-in user data

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<bool> checkUserExists(String phoneNumber) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .get();
      return userDoc.exists;
    } catch (e) {
      errorMessage = 'Error checking user: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> sendOTP(String phoneNumber) async {
    setLoading(true);
    try {
      final response = await http.get(
        Uri.parse(
            'https://2factor.in/API/V1/$apiKey/SMS/$phoneNumber/AUTOGEN/$otpTemplateName'),
      );
      final responseData = json.decode(response.body);

      if (responseData['Status'] == 'Success') {
        otpSessionId = responseData['Details'];
        isOtpSent = true;
      } else {
        errorMessage = 'Failed to send OTP. Try again.';
      }
    } catch (e) {
      errorMessage = 'Error sending OTP: $e';
    } finally {
      setLoading(false);
    }
  }

  Future<bool> verifyOTP(String phoneNumber, String otpEntered) async {
    if (otpSessionId == null) {
      errorMessage = 'OTP session ID is null. Please request OTP again.';
      notifyListeners();
      return false;
    }

    setLoading(true);
    try {
      final response = await http.get(
        Uri.parse(
            'https://2factor.in/API/V1/$apiKey/SMS/VERIFY/$otpSessionId/$otpEntered'),
      );
      final responseData = json.decode(response.body);

      if (responseData['Status'] == 'Success') {
        await fetchUserData(
            phoneNumber); // Fetch user data after OTP verification
        return true;
      } else {
        errorMessage = 'OTP verification failed. Try again.';
      }
    } catch (e) {
      errorMessage = 'Error verifying OTP: $e';
    } finally {
      setLoading(false);
    }
    return false;
  }

  Future<void> fetchUserData(String phoneNumber) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .get();

      if (userDoc.exists) {
        currentUser = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
        userPhoneNumber = phoneNumber;
        notifyListeners();
      } else {
        errorMessage = "User data not found.";
        notifyListeners();
      }
    } catch (e) {
      errorMessage = "Error fetching user data: $e";
      notifyListeners();
    }
  }
}
