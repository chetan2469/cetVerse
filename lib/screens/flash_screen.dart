import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:provider/provider.dart';
import 'package:get_phone_number/get_phone_number.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shimmer/shimmer.dart';

import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/screens/dashboard_page.dart';
import 'package:cet_verse/core/auth/phone_auth_screen.dart';
import 'package:cet_verse/core/config/firebase_options.dart';

class FlashScreen extends StatefulWidget {
  const FlashScreen({super.key});

  @override
  State<FlashScreen> createState() => _FlashScreenState();
}

class _FlashScreenState extends State<FlashScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  bool _isLoading = true;
  String _loadingText = 'Initializing...';

  final _slideImages = const ['assets/stude1.jpg', 'assets/stude2.jpg'];

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAutoSlides();

    // Start initialization immediately without unnecessary delays
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  void _startAutoSlides() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      _currentPage = (_currentPage + 1) % _slideImages.length;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() {});
    });
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Initialize Firebase
      _updateLoadingText('Setting up Firebase...');
      await _ensureFirebase();

      // Step 2: Initialize TeX (if needed, parallel with auth check)
      final texFuture = _initializeTeX();

      // Step 3: Check user authentication
      _updateLoadingText('Checking authentication...');
      final authFuture = _checkUserLogin();

      // Wait for both to complete
      await Future.wait([texFuture, authFuture]);
    } catch (e) {
      debugPrint('Initialization error: $e');
      _updateLoadingText('Starting app...');
      // Fallback to phone auth after short delay
      await Future.delayed(const Duration(milliseconds: 500));
      _navigateToPhoneAuth();
    }
  }

  void _updateLoadingText(String text) {
    if (!mounted) return;
    setState(() => _loadingText = text);
  }

  Future<void> _ensureFirebase() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  }

  Future<void> _initializeTeX() async {
    if (!kIsWeb) {
      try {
        await TeXRenderingServer.start();
      } catch (e) {
        debugPrint('TeX initialization failed: $e');
      }
    }
  }

  Future<void> _checkUserLogin() async {
    final auth = context.read<AuthProvider>();

    // Restore session first
    await auth.restoreSession();
    if (!mounted) return;

    // If user already exists, navigate to dashboard
    if (auth.currentUser != null) {
      _updateLoadingText('Welcome back!');
      await Future.delayed(const Duration(milliseconds: 300));
      _navigateToDashboard();
      return;
    }

    // Try to get phone number and check if user exists
    _updateLoadingText('Detecting phone number...');
    try {
      final phone = await GetPhoneNumber()
          .get()
          .timeout(const Duration(seconds: 2))
          .then<String?>((raw) {
        if (raw == null) return null;
        final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
        return digits.replaceFirst(RegExp(r'^(?:0|91)?'), '');
      }).catchError((_) => null);

      if (phone != null && phone.isNotEmpty) {
        _updateLoadingText('Checking user data...');
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(phone)
            .get()
            .timeout(const Duration(seconds: 3));

        if (!mounted) return;

        if (userDoc.exists) {
          _updateLoadingText('Logging you in...');
          await auth.fetchUserData(phone);
          if (!mounted) return;
          _navigateToDashboard();
          return;
        }
      }
    } catch (e) {
      debugPrint('Phone detection/user lookup error: $e');
    }

    // No existing user found, go to phone auth
    _updateLoadingText('Ready to start!');
    await Future.delayed(const Duration(milliseconds: 300));
    _navigateToPhoneAuth();
  }

  void _navigateToDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DashboardPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToPhoneAuth() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PhoneAuthScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade100,
              Colors.purple.shade50,
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Section
                    _buildLogoSection(),

                    const SizedBox(height: 40),

                    // Loading Section
                    _buildLoadingSection(),

                    const SizedBox(height: 50),

                    // Image Carousel Section
                    _buildImageCarousel(),

                    const SizedBox(height: 20),

                    // Page Indicators
                    _buildPageIndicators(),

                    const SizedBox(height: 40),

                    // App Info
                    _buildAppInfo(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/cetverse.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.school,
                      size: 80,
                      color: Colors.blue.shade600,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'CET Verse',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your CET Preparation Companion',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Custom Loading Indicator
          Shimmer.fromColors(
            baseColor: Colors.blue.shade300,
            highlightColor: Colors.blue.shade100,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                ),
              ),
              child: const Icon(
                Icons.refresh,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Loading Text with Animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _loadingText,
              key: ValueKey(_loadingText),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 8),

          // Progress Bar
          Container(
            width: 200,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.blue.shade600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: PageView.builder(
          controller: _pageController,
          itemCount: _slideImages.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (_, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.blue.shade100, Colors.purple.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  _slideImages[i],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade200,
                            Colors.purple.shade200
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Student ${i + 1}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _slideImages.length,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _currentPage == i ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: _currentPage == i
                ? LinearGradient(
                    colors: [Colors.blue.shade600, Colors.purple.shade600],
                  )
                : null,
            color: _currentPage == i ? null : Colors.grey.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified,
            size: 16,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 8),
          Text(
            'Powered by CET Verse Team',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
