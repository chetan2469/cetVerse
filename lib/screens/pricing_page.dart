import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/paymentGetway/RazorpayQuickPayPage.dart';
import 'package:cet_verse/screens/NeedHelp.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class PricingPage extends StatefulWidget {
  const PricingPage({super.key});

  @override
  State<PricingPage> createState() => _PricingPageState();
}

class _PricingPageState extends State<PricingPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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
    super.dispose();
  }

  // --- helpers ---
  int _levelFor(String? plan) {
    switch (plan) {
      case 'Plus':
        return 1;
      case 'Pro':
        return 2;
      case 'Starter':
      default:
        return 0;
    }
  }

  Future<void> _activateFreePlan(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final phone = auth.userPhoneNumber;
    if (phone == null) {
      _showErrorMessage('Please log in to activate');
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('users').doc(phone).set(
        {
          'subscription': {
            'planType': 'Starter',
            'status': 'active',
            'amountPaid': 0,
            'paymentMethod': 'none',
            'startDate': FieldValue.serverTimestamp(),
            'endDate': null,
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
          }
        },
        SetOptions(merge: true),
      );
      await auth.fetchUserData(phone);
      _showSuccessMessage('Starter plan activated successfully!');
    } catch (e) {
      _showErrorMessage('Failed to activate plan: $e');
    }
  }

  Future<void> _startPaidPlan(
    BuildContext context, {
    required String planCode,
    required double rupees,
  }) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final phone = auth.userPhoneNumber;
    if (phone == null) {
      _showErrorMessage('Please log in to purchase a plan');
      return;
    }
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RazorpayQuickPayPage(
          mobile: phone,
          priceRupees: rupees,
          planName: planCode,
          customerEmail: null,
          displayName: 'CET Verse',
        ),
      ),
    );
    if (result is Map && result['ok'] == true) {
      await auth.fetchUserData(phone);
      _showSuccessMessage('$planCode plan activated successfully!');
    } else {
      _showErrorMessage('Payment not completed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentPlan = auth.getPlanType ?? 'Starter';
    final currentLevel = _levelFor(currentPlan);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(screenWidth),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildHeroSection(screenWidth),
                      SizedBox(height: screenHeight * 0.03),
                      _buildPricingCards(context, currentLevel, screenWidth),
                      SizedBox(height: screenHeight * 0.04),
                      _buildPaymentMethods(screenWidth),
                      SizedBox(height: screenHeight * 0.02),
                      _buildFooterSection(screenWidth),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(double screenWidth) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF1A1A1A),
            size: 20,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Choose Your Plan',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[50]!,
                Colors.purple[50]!,
                Colors.white,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(double screenWidth) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[600]!,
            Colors.purple[600]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.rocket_launch,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            'Unlock Your Full Potential',
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.06,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the perfect plan for your CET preparation journey\nand achieve your dream score',
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.035,
              color: Colors.white.withOpacity(0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCards(
      BuildContext context, int currentLevel, double screenWidth) {
    final plans = ['Starter', 'Plus', 'Pro'];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
      child: Column(
        children: plans.map((plan) {
          final index = plans.indexOf(plan);
          return AnimatedContainer(
            duration: Duration(milliseconds: 300 + (index * 100)),
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildPlanCard(context, plan, currentLevel, screenWidth),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, String planType, int currentLevel,
      double screenWidth) {
    final planData = _getPlanData(planType);
    final level = _levelFor(planType);
    final isCurrent = currentLevel == level;
    final isDisabled = currentLevel > level;
    final isPopular = planType == 'Pro';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isCurrent
                ? Colors.green.withOpacity(0.2)
                : isPopular
                    ? Colors.purple.withOpacity(0.15)
                    : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: isCurrent
            ? Border.all(color: Colors.green, width: 2)
            : isPopular
                ? Border.all(color: Colors.purple, width: 2)
                : null,
      ),
      child: Stack(
        children: [
          if (isPopular)
            Positioned(
              top: 0,
              left: 20,
              right: 20,
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[400]!, Colors.orange[600]!],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Text(
                    '🔥 MOST POPULAR',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(24).copyWith(top: isPopular ? 44 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: planType == 'Pro'
                                        ? [
                                            Colors.purple[400]!,
                                            Colors.purple[600]!
                                          ]
                                        : planType == 'Plus'
                                            ? [
                                                Colors.blue[400]!,
                                                Colors.blue[600]!
                                              ]
                                            : [
                                                Colors.green[400]!,
                                                Colors.green[600]!
                                              ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  planType == 'Pro'
                                      ? Icons.diamond
                                      : planType == 'Plus'
                                          ? Icons.star
                                          : Icons.favorite,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    planData['name'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  Text(
                                    planData['subtitle'] ?? '',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                planData['price'],
                                style: GoogleFonts.poppins(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: planType == 'Pro'
                                      ? Colors.purple[600]
                                      : planType == 'Plus'
                                          ? Colors.blue[600]
                                          : Colors.green[600],
                                ),
                              ),
                              if (planData['period'] != null)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 4, bottom: 4),
                                  child: Text(
                                    planData['period'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'ACTIVE',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What you\'ll get:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...planData['features'].map<Widget>((feature) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: feature['available']
                                      ? Colors.green[100]
                                      : Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  feature['available']
                                      ? Icons.check
                                      : Icons.close,
                                  size: 14,
                                  color: feature['available']
                                      ? Colors.green[600]
                                      : Colors.grey[500],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  feature['text'],
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: feature['available']
                                        ? const Color(0xFF374151)
                                        : const Color(0xFF9CA3AF),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: (isCurrent || isDisabled)
                        ? null
                        : () {
                            if (planType == 'Starter') {
                              _activateFreePlan(context);
                            } else {
                              _startPaidPlan(
                                context,
                                planCode: planType,
                                rupees: planType == 'Plus' ? 129 : 149,
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrent || isDisabled
                          ? Colors.grey[300]
                          : planType == 'Pro'
                              ? Colors.purple[600]
                              : planType == 'Plus'
                                  ? Colors.blue[600]
                                  : Colors.green[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: isCurrent || isDisabled ? 0 : 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isCurrent && !isDisabled)
                          Icon(
                            planType == 'Starter'
                                ? Icons.rocket_launch
                                : Icons.upgrade,
                            size: 20,
                          ),
                        if (!isCurrent && !isDisabled) const SizedBox(width: 8),
                        Text(
                          isCurrent
                              ? 'Current Plan'
                              : isDisabled
                                  ? 'Downgrade N/A'
                                  : planType == 'Starter'
                                      ? 'Get Started Free'
                                      : 'Upgrade Now',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(double screenWidth) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.green[600]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.security,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Secure Payment Methods',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      'Your data is protected with 256-bit SSL encryption',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 3,
            children: [
              _buildPaymentMethodCard(
                  'UPI', Icons.account_balance_wallet, Colors.purple),
              _buildPaymentMethodCard('Cards', Icons.credit_card, Colors.blue),
              _buildPaymentMethodCard(
                  'Net Banking', Icons.account_balance, Colors.green),
              _buildPaymentMethodCard('Wallets', Icons.wallet, Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection(double screenWidth) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[50]!, Colors.white],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.help_outline,
            size: 32,
            color: Colors.blue[600],
          ),
          const SizedBox(height: 12),
          Text(
            'Need Help Choosing?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contact our support team for personalized recommendations',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NeedHelp()),
              );
            },
            child: Text(
              'Contact Support',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blue[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getPlanData(String planType) {
    switch (planType) {
      case 'Starter':
        return {
          'name': 'Starter Plan',
          'subtitle': 'Perfect for beginners',
          'price': 'FREE',
          'period': null,
          'features': [
            {'text': 'Limited MHT CET PYQs access', 'available': true},
            {'text': '1 Mock test per subject', 'available': true},
            {'text': 'Basic performance tracking', 'available': true},
            {'text': 'Read-only topper profiles', 'available': true},
            {'text': 'Board PYQs access', 'available': false},
            {'text': 'Chapter-wise notes download', 'available': false},
          ]
        };
      case 'Plus':
        return {
          'name': 'Plus Plan',
          'subtitle': 'Most comprehensive preparation',
          'price': '₹129',
          'period': '/year',
          'features': [
            {'text': 'Unlimited MHT CET PYQs', 'available': true},
            {'text': 'Complete Board PYQs access', 'available': true},
            {'text': 'Chapter-wise notes & materials', 'available': true},
            {'text': 'Topper notes download', 'available': true},
            {'text': '2 Mock tests per subject', 'available': true},
            {'text': 'Full mock test series', 'available': false},
          ]
        };
      case 'Pro':
        return {
          'name': 'Pro Plan',
          'subtitle': 'Ultimate CET preparation',
          'price': '₹149',
          'period': '/year',
          'features': [
            {'text': 'Everything in Plus plan', 'available': true},
            {'text': 'Complete mock test series', 'available': true},
            {'text': 'Full topper profiles access', 'available': true},
            {'text': 'Priority feature access', 'available': true},
            {'text': 'Advanced performance analytics', 'available': true},
            {'text': 'Premium support & guidance', 'available': true},
          ]
        };
      default:
        return {};
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
}
