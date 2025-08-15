import 'package:cet_verse/core/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  final String apiKey = 'a377dfe4-53ca-11ef-8b60-0200cd936042';
  final String otpTemplateName = 'OTP1';

  bool isLoading = false;
  bool isOtpSent = false;
  bool isPasswordLogin = false;
  String? otpSessionId;
  String? errorMessage, userPhoneNumber;
  UserModel? currentUser;

  String? userType;
  String? planType;

  double physicsSolved = 0.0;
  double chemistrySolved = 0.0;
  double mathsSolved = 0.0;
  double bioSolved = 0.0;

  double totalPhysicsSolved = 0.0;
  double totalChemistrySolved = 0.0;
  double totalMathsSolved = 0.0;
  double totalBiologySolved = 0.0;

  static const String _loggedInKey = 'isLoggedIn';
  static const String _phoneKey = 'userPhoneNumber';
  static const String _passwordKey = 'userPassword';

  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<bool> checkUserExists(String phoneNumber) async {
    try {
      errorMessage = null; // Clear previous error
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .get();
      return userDoc.exists;
    } catch (e) {
      errorMessage = 'Error checking user: $e';
      print('checkUserExists error: $e'); // Debug log
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithPassword(String mobileNumber, String password) async {
    try {
      setLoading(true);
      errorMessage = null; // Clear previous error
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(mobileNumber)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final storedPassword = userData['password'] as String?;

        if (storedPassword != null && storedPassword == password) {
          isPasswordLogin = true;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_loggedInKey, true);
          await prefs.setString(_phoneKey, mobileNumber);
          await prefs.setString(_passwordKey, password);
          await fetchUserData(mobileNumber);
          print('Password login successful for $mobileNumber');
          setLoading(false);
          return true;
        } else {
          errorMessage = 'Incorrect password';
        }
      } else {
        errorMessage = 'Mobile number not found';
      }
    } catch (e) {
      errorMessage = 'Login failed: $e';
      print('loginWithPassword error: $e');
    } finally {
      setLoading(false);
      notifyListeners();
    }
    return false;
  }

  Future<bool> tryAutoLogin() async {
    try {
      errorMessage = null; // Clear previous error
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_loggedInKey) ?? false;
      if (!isLoggedIn) return false;

      final phoneNumber = prefs.getString(_phoneKey);
      final password = prefs.getString(_passwordKey);

      if (phoneNumber != null && password != null) {
        return await loginWithPassword(phoneNumber, password);
      }
      return false;
    } catch (e) {
      errorMessage = 'Auto-login failed: $e';
      print('tryAutoLogin error: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> restoreSession() async {
    try {
      errorMessage = null; // Clear previous error
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_loggedInKey) ?? false;
      if (isLoggedIn) {
        userPhoneNumber = prefs.getString(_phoneKey);
        if (userPhoneNumber != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userPhoneNumber)
              .get();
          if (userDoc.exists) {
            currentUser =
                UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
            userType = currentUser?.userType;
            final subscription = currentUser?.subscription;
            planType = subscription != null
                ? subscription['planType'] as String?
                : null;
            print('Session restored for $userPhoneNumber, userType: $userType');
            notifyListeners();
          }
        }
      }
    } catch (e) {
      errorMessage = 'Error restoring session: $e';
      print('restoreSession error: $e');
      notifyListeners();
    }
  }

  Future<void> sendOTP(String phoneNumber) async {
    setLoading(true);
    errorMessage = null; // Clear previous error
    try {
      final response = await http.get(
        Uri.parse(
            'https://2factor.in/API/V1/$apiKey/SMS/$phoneNumber/AUTOGEN/$otpTemplateName'),
      );
      final responseData = json.decode(response.body);

      if (responseData['Status'] == 'Success') {
        otpSessionId = responseData['Details'];
        isOtpSent = true;
        print('OTP sent to $phoneNumber, sessionId: $otpSessionId');
      } else {
        errorMessage = 'Failed to send OTP. Try again.';
      }
    } catch (e) {
      errorMessage = 'Error sending OTP: $e';
      print('sendOTP error: $e');
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  Future<bool> verifyOTP(String phoneNumber, String otpEntered) async {
    if (otpSessionId == null) {
      errorMessage = 'OTP session ID is null. Please request OTP again.';
      print('verifyOTP error: null sessionId');
      notifyListeners();
      return false;
    }

    setLoading(true);
    errorMessage = null; // Clear previous error
    try {
      final response = await http.get(
        Uri.parse(
            'https://2factor.in/API/V1/$apiKey/SMS/VERIFY/$otpSessionId/$otpEntered'),
      );
      final responseData = json.decode(response.body);

      if (responseData['Status'] == 'Success') {
        await fetchUserData(phoneNumber);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_loggedInKey, true);
        await prefs.setString(_phoneKey, phoneNumber);
        print('OTP verified for $phoneNumber');
        return true;
      } else {
        errorMessage = 'OTP verification failed. Try again.';
      }
    } catch (e) {
      errorMessage = 'Error verifying OTP: $e';
      print('verifyOTP error: $e');
    } finally {
      setLoading(false);
      notifyListeners();
    }
    return false;
  }

  Future<void> fetchUserData(String phoneNumber) async {
    try {
      errorMessage = null; // Clear previous error
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(phoneNumber);
      final userDoc = await userRef.get();

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        currentUser = UserModel.fromMap(userData);
        userType = userData['userType'] as String?;
        final subscription = userData['subscription'] as Map<String, dynamic>?;
        planType =
            subscription != null ? subscription['planType'] as String? : null;

        if (planType == null) {
          planType = 'Starter';
          await userRef.set(
            {
              'subscription': {'planType': 'Starter'}
            },
            SetOptions(merge: true),
          );
        }

        final solvedQuestions =
            userData['user solve questions'] as Map<String, dynamic>?;
        if (solvedQuestions != null) {
          physicsSolved =
              (solvedQuestions['physics'] as num?)?.toDouble() ?? 0.0;
          chemistrySolved =
              (solvedQuestions['chemistry'] as num?)?.toDouble() ?? 0.0;
          mathsSolved = (solvedQuestions['maths'] as num?)?.toDouble() ?? 0.0;
          bioSolved = (solvedQuestions['biology'] as num?)?.toDouble() ?? 0.0;
        } else {
          physicsSolved = 0.0;
          chemistrySolved = 0.0;
          mathsSolved = 0.0;
          bioSolved = 0.0;
        }

        final totalSolvedQuestions =
            userData['total solve questions'] as Map<String, dynamic>?;
        if (totalSolvedQuestions != null) {
          totalPhysicsSolved =
              (totalSolvedQuestions['physics'] as num?)?.toDouble() ?? 0.0;
          totalChemistrySolved =
              (totalSolvedQuestions['chemistry'] as num?)?.toDouble() ?? 0.0;
          totalMathsSolved =
              (totalSolvedQuestions['maths'] as num?)?.toDouble() ?? 0.0;
          totalBiologySolved =
              (totalSolvedQuestions['biology'] as num?)?.toDouble() ?? 0.0;
        } else {
          final defaultTotalSolvedQuestions = {
            'physics': 0,
            'chemistry': 0,
            'maths': 0,
            'biology': 0,
          };
          await userRef.set(
            {'total solve questions': defaultTotalSolvedQuestions},
            SetOptions(merge: true),
          );
          totalPhysicsSolved = 0.0;
          totalChemistrySolved = 0.0;
          totalMathsSolved = 0.0;
          totalBiologySolved = 0.0;
        }

        userPhoneNumber = phoneNumber;
        print(
            'User data fetched for $phoneNumber, userType: $userType, planType: $planType');
        notifyListeners();
      } else {
        errorMessage = "User data not found.";
        print('fetchUserData error: User data not found for $phoneNumber');
        notifyListeners();
      }
    } catch (e) {
      errorMessage = "Error fetching user data: $e";
      print('fetchUserData error: $e');
      notifyListeners();
    }
  }

  String? get getUserType => userType;
  String? get getPlanType => planType;

  double get getPhysicsSolved => physicsSolved;
  double get getChemistrySolved => chemistrySolved;
  double get getMathsSolved => mathsSolved;
  double get getBioSolved => bioSolved;

  double get getTotalPhysicsSolved => totalPhysicsSolved;
  double get getTotalChemistrySolved => totalChemistrySolved;
  double get getTotalMathsSolved => totalMathsSolved;
  double get getTotalBiologySolved => totalBiologySolved;

  Future<void> clearSession() async {
    try {
      currentUser = null;
      userPhoneNumber = null;
      userType = null;
      planType = null;
      otpSessionId = null;
      isOtpSent = false;
      isPasswordLogin = false;
      physicsSolved = 0.0;
      chemistrySolved = 0.0;
      mathsSolved = 0.0;
      bioSolved = 0.0;
      totalPhysicsSolved = 0.0;
      totalChemistrySolved = 0.0;
      totalMathsSolved = 0.0;
      totalBiologySolved = 0.0;
      errorMessage = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_loggedInKey);
      await prefs.remove(_phoneKey);
      await prefs.remove(_passwordKey);
      print('Session cleared successfully');
      notifyListeners();
    } catch (e) {
      errorMessage = 'Error clearing session: $e';
      print('clearSession error: $e');
      notifyListeners();
    }
  }
}
