// lib/core/auth/AuthProvider.dart
import 'dart:async';
import 'dart:convert';

import 'package:cet_verse/core/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  // ===== OTP API (2Factor) =====
  final String apiKey = 'a377dfe4-53ca-11ef-8b60-0200cd936042';
  final String otpTemplateName = 'OTP1';

  // ===== UI / State =====
  bool isLoading = false;
  bool isOtpSent = false;
  bool isPasswordLogin = false;
  String? otpSessionId;
  String? errorMessage;
  String? userPhoneNumber;
  UserModel? currentUser;

  // ===== Subscription / Plan =====
  String? userType; // "Student" / "Admin"
  String? planType; // "Starter" / "Plus" / "Pro"
  String? subscriptionStatus; // "active" / "expired" / null
  num? amountPaid; // last payment
  String? paymentMethod; // 'razorpay' / 'none' / null
  Timestamp? startDateTs;
  Timestamp? endDateTs;

  // ===== Features (as received from Firestore) =====
  Map<String, dynamic> _features = {};

  // ---- Feature getters (centralized) ----
  // Strings
  String get mhtCetPyqsAccess =>
      (_features['mhtCetPyqsAccess'] as String?) ?? 'limited';
  String get topperProfilesAccess =>
      (_features['topperProfilesAccess'] as String?) ?? 'read-only';

  // Booleans
  bool get boardPyqsAccess => (_features['boardPyqsAccess'] as bool?) ?? false;
  bool get chapterWiseNotesAccess =>
      (_features['chapterWiseNotesAccess'] as bool?) ?? false;
  bool get topperNotesDownload =>
      (_features['topperNotesDownload'] as bool?) ?? false;
  bool get fullMockTestSeries =>
      (_features['fullMockTestSeries'] as bool?) ?? false;
  bool get performanceTracking =>
      (_features['performanceTracking'] as bool?) ?? true;
  bool get priorityFeatureAccess =>
      (_features['priorityFeatureAccess'] as bool?) ?? false;

  /// Tests count: if `fullMockTestSeries==true` (Pro equivalence), treat as Unlimited.
  int get mockTestsPerSubject {
    if (fullMockTestSeries || isPro) return 9999; // Unlimited for UI/gating
    final raw = _features['mockTestsPerSubject'];
    return (raw is num) ? raw.toInt() : 0;
  }

  // ---- Plan flags (case-insensitive) ----
  bool get isStarter => (planType ?? 'Starter').toLowerCase() == 'starter';
  bool get isPlus => (planType ?? '').toLowerCase() == 'plus';
  bool get isPro => (planType ?? '').toLowerCase() == 'pro';
  bool get isAdmin => (userType ?? '').toLowerCase() == 'admin';

  // ===== Solve stats =====
  double physicsSolved = 0.0;
  double chemistrySolved = 0.0;
  double mathsSolved = 0.0;
  double bioSolved = 0.0;

  double totalPhysicsSolved = 0.0;
  double totalChemistrySolved = 0.0;
  double totalMathsSolved = 0.0;
  double totalBiologySolved = 0.0;

  // ===== Local Storage Keys =====
  static const String _loggedInKey = 'isLoggedIn';
  static const String _phoneKey = 'userPhoneNumber';
  static const String _passwordKey = 'userPassword';

  // ===== Firestore listener =====
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  // -------------------- Helpers --------------------
  void setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<bool> checkUserExists(String phoneNumber) async {
    try {
      errorMessage = null;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .get();
      return doc.exists;
    } catch (e) {
      errorMessage = 'Error checking user: $e';
      notifyListeners();
      return false;
    }
  }

  // -------------------- Auth (password) --------------------
  Future<bool> loginWithPassword(String mobileNumber, String password) async {
    try {
      setLoading(true);
      errorMessage = null;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(mobileNumber)
          .get();

      if (!doc.exists) {
        errorMessage = 'Mobile number not found';
        return false;
      }

      final data = doc.data() as Map<String, dynamic>;
      final storedPassword = data['password'] as String?;
      if (storedPassword == null || storedPassword != password) {
        errorMessage = 'Incorrect password';
        return false;
      }

      isPasswordLogin = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_loggedInKey, true);
      await prefs.setString(_phoneKey, mobileNumber);
      await prefs.setString(_passwordKey, password);

      await _attachUserListener(mobileNumber);
      return true;
    } catch (e) {
      errorMessage = 'Login failed: $e';
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  Future<bool> tryAutoLogin() async {
    try {
      errorMessage = null;
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_loggedInKey) ?? false;
      if (!isLoggedIn) return false;

      final phoneNumber = prefs.getString(_phoneKey);
      final password = prefs.getString(_passwordKey);
      if (phoneNumber == null || password == null) return false;

      return await loginWithPassword(phoneNumber, password);
    } catch (e) {
      errorMessage = 'Auto-login failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> restoreSession() async {
    try {
      errorMessage = null;
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_loggedInKey) ?? false;
      if (!isLoggedIn) return;

      final phone = prefs.getString(_phoneKey);
      if (phone != null) {
        await _attachUserListener(phone);
      }
    } catch (e) {
      errorMessage = 'Error restoring session: $e';
      notifyListeners();
    }
  }

  // -------------------- OTP --------------------
  Future<void> sendOTP(String phoneNumber) async {
    setLoading(true);
    errorMessage = null;
    try {
      final url = Uri.parse(
          'https://2factor.in/API/V1/$apiKey/SMS/$phoneNumber/AUTOGEN/$otpTemplateName');
      final resp = await http.get(url);
      final body = json.decode(resp.body);

      if (body['Status'] == 'Success') {
        otpSessionId = body['Details'];
        isOtpSent = true;
      } else {
        errorMessage = 'Failed to send OTP. Try again.';
      }
    } catch (e) {
      errorMessage = 'Error sending OTP: $e';
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  Future<bool> verifyOTP(String phoneNumber, String otpEntered) async {
    if (otpSessionId == null) {
      errorMessage = 'OTP session ID is null. Please request OTP again.';
      notifyListeners();
      return false;
    }

    setLoading(true);
    errorMessage = null;
    try {
      final url = Uri.parse(
          'https://2factor.in/API/V1/$apiKey/SMS/VERIFY/$otpSessionId/$otpEntered');
      final resp = await http.get(url);
      final body = json.decode(resp.body);

      if (body['Status'] == 'Success') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_loggedInKey, true);
        await prefs.setString(_phoneKey, phoneNumber);
        await _attachUserListener(phoneNumber);
        return true;
      } else {
        errorMessage = 'OTP verification failed. Try again.';
        return false;
      }
    } catch (e) {
      errorMessage = 'Error verifying OTP: $e';
      return false;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }

  // -------------------- Firestore binding --------------------
  Future<void> _attachUserListener(String phone) async {
    // Cancel any previous subscription
    if (_userSub != null) {
      await _userSub!.cancel();
      _userSub = null;
    }

    userPhoneNumber = phone;

    // Live updates
    _userSub = FirebaseFirestore.instance
        .collection('users')
        .doc(phone)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final data = snap.data()!;
      _applyUserData(data);
      notifyListeners();
    }, onError: (e) {
      errorMessage = 'Listener error: $e';
      notifyListeners();
    });

    // Prime once immediately
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(phone).get();
    if (doc.exists) {
      _applyUserData(doc.data() as Map<String, dynamic>);
      notifyListeners();
    }
  }

  void _applyUserData(Map<String, dynamic> userData) {
    // Keep UserModel in sync for pages using it directly
    try {
      currentUser = UserModel.fromMap(userData);
    } catch (_) {
      currentUser = null;
    }

    userType = (userData['userType'] as String?) ?? userType;

    // ---- Subscription
    final sub = userData['subscription'] as Map<String, dynamic>?;
    planType = sub != null ? sub['planType'] as String? : planType;
    subscriptionStatus =
        sub != null ? sub['status'] as String? : subscriptionStatus;
    amountPaid = sub != null ? sub['amountPaid'] as num? : amountPaid;
    paymentMethod =
        sub != null ? sub['paymentMethod'] as String? : paymentMethod;
    startDateTs = sub != null ? sub['startDate'] as Timestamp? : startDateTs;
    endDateTs = sub != null ? sub['endDate'] as Timestamp? : endDateTs;

    // Ensure subscription defaults for missing docs
    if (planType == null) {
      planType = 'Starter';
      FirebaseFirestore.instance.collection('users').doc(userPhoneNumber).set({
        'subscription': {
          'planType': 'Starter',
          'status': 'active',
          'amountPaid': 0,
          'paymentMethod': 'none',
          'startDate': FieldValue.serverTimestamp(),
          'endDate': null,
        },
      }, SetOptions(merge: true));
    }

    // ---- Features
    final f = userData['features'] as Map<String, dynamic>?;
    if (f != null) {
      _features = Map<String, dynamic>.from(f);
    } else {
      // Starter defaults
      _features = {
        'mhtCetPyqsAccess': 'limited',
        'boardPyqsAccess': false,
        'chapterWiseNotesAccess': false,
        'topperNotesDownload': false,
        'mockTestsPerSubject': 1,
        'fullMockTestSeries': false,
        'topperProfilesAccess': 'read-only',
        'performanceTracking': true,
        'priorityFeatureAccess': false,
      };
      FirebaseFirestore.instance.collection('users').doc(userPhoneNumber).set(
        {'features': _features},
        SetOptions(merge: true),
      );
    }

    // ---- Solve stats
    final solved = userData['user solve questions'] as Map<String, dynamic>?;
    if (solved != null) {
      physicsSolved = (solved['physics'] as num?)?.toDouble() ?? 0.0;
      chemistrySolved = (solved['chemistry'] as num?)?.toDouble() ?? 0.0;
      mathsSolved = (solved['maths'] as num?)?.toDouble() ?? 0.0;
      bioSolved = (solved['biology'] as num?)?.toDouble() ?? 0.0;
    } else {
      physicsSolved = chemistrySolved = mathsSolved = bioSolved = 0.0;
    }

    final total = userData['total solve questions'] as Map<String, dynamic>?;
    if (total != null) {
      totalPhysicsSolved = (total['physics'] as num?)?.toDouble() ?? 0.0;
      totalChemistrySolved = (total['chemistry'] as num?)?.toDouble() ?? 0.0;
      totalMathsSolved = (total['maths'] as num?)?.toDouble() ?? 0.0;
      totalBiologySolved = (total['biology'] as num?)?.toDouble() ?? 0.0;
    } else {
      final defaults = {'physics': 0, 'chemistry': 0, 'maths': 0, 'biology': 0};
      FirebaseFirestore.instance.collection('users').doc(userPhoneNumber).set(
        {'total solve questions': defaults},
        SetOptions(merge: true),
      );
      totalPhysicsSolved =
          totalChemistrySolved = totalMathsSolved = totalBiologySolved = 0.0;
    }
  }

  // -------------------- Public getters --------------------
  String? get getUserType => userType;
  String? get getPlanType => planType;

  Map<String, dynamic> get getFeatures => Map<String, dynamic>.from(_features);

  DateTime? get startDate =>
      (startDateTs != null) ? startDateTs!.toDate() : null;
  DateTime? get endDate => (endDateTs != null) ? endDateTs!.toDate() : null;

  double get getPhysicsSolved => physicsSolved;
  double get getChemistrySolved => chemistrySolved;
  double get getMathsSolved => mathsSolved;
  double get getBioSolved => bioSolved;

  double get getTotalPhysicsSolved => totalPhysicsSolved;
  double get getTotalChemistrySolved => totalChemistrySolved;
  double get getTotalMathsSolved => totalMathsSolved;
  double get getTotalBiologySolved => totalBiologySolved;

  // -------------------- Payment history helpers --------------------
  Stream<QuerySnapshot<Map<String, dynamic>>> paymentHistoryStream({
    int limit = 50,
  }) {
    final phone = userPhoneNumber;
    if (phone == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(phone)
        .collection('paymentHistory')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  Future<List<Map<String, dynamic>>> getRecentPayments({int limit = 50}) async {
    final phone = userPhoneNumber;
    if (phone == null) return [];
    final qs = await FirebaseFirestore.instance
        .collection('users')
        .doc(phone)
        .collection('paymentHistory')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return qs.docs.map((d) => d.data()).toList();
  }

  // -------------------- Manual refresh --------------------
  Future<void> fetchUserData(String phoneNumber) async {
    try {
      errorMessage = null;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .get();
      if (doc.exists) {
        await _attachUserListener(phoneNumber); // ensure live updates
      } else {
        errorMessage = 'User data not found.';
      }
    } catch (e) {
      errorMessage = 'Error fetching user data: $e';
    } finally {
      notifyListeners();
    }
  }

  // -------------------- Clear session --------------------
  Future<void> clearSession() async {
    try {
      await _userSub?.cancel();
      _userSub = null;

      currentUser = null;
      userPhoneNumber = null;
      userType = null;
      planType = null;
      subscriptionStatus = null;
      amountPaid = null;
      paymentMethod = null;
      startDateTs = null;
      endDateTs = null;
      _features = {};

      otpSessionId = null;
      isOtpSent = false;
      isPasswordLogin = false;

      physicsSolved = chemistrySolved = mathsSolved = bioSolved = 0.0;
      totalPhysicsSolved =
          totalChemistrySolved = totalMathsSolved = totalBiologySolved = 0.0;

      errorMessage = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_loggedInKey);
      await prefs.remove(_phoneKey);
      await prefs.remove(_passwordKey);
      notifyListeners();
    } catch (e) {
      errorMessage = 'Error clearing session: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _userSub?.cancel();
    super.dispose();
  }
}
