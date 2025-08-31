// lib/pages/PricingPage.dart
import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/paymentGetway/RazorpayQuickPayPage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PricingPage extends StatelessWidget {
  const PricingPage({super.key});

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to activate')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starter plan activated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _startPaidPlan(
    BuildContext context, {
    required String planCode, // 'Plus' or 'Pro'
    required double rupees,
  }) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final phone = auth.userPhoneNumber;
    if (phone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to purchase a plan')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$planCode plan activated successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment not completed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final currentPlan = auth.getPlanType ?? 'Starter';
    final currentLevel = _levelFor(currentPlan);

    // Card levels
    const starterLevel = 0;
    const plusLevel = 1;
    const proLevel = 2;

    // Disable logic (no downgrades)
    final starterDisabled =
        currentLevel > starterLevel; // Plus/Pro -> disable Starter
    final plusDisabled = currentLevel > plusLevel; // Pro -> disable Plus
    const proDisabled = false; // Upgrades allowed anytime

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CETVerse Pricing Plans',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Your Plan',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unlock your potential with the perfect plan for you',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Starter
              PricingCard(
                planName: 'Starter Plan',
                price: '₹0',
                features: const [
                  'MHT CET PYQs Access: Limited',
                  'Mock Tests per Subject: 1',
                  'Topper Profiles: Read-only',
                  'Performance Tracking: Yes',
                ],
                isCurrent: currentLevel == starterLevel,
                isDisabled: starterDisabled && currentLevel != starterLevel,
                disabledReason: 'Downgrade not available',
                onPurchase: () => _activateFreePlan(context),
                buttonText: currentLevel == starterLevel
                    ? 'Current Plan'
                    : 'Get Started',
                buttonColor: Colors.green,
              ),
              const SizedBox(height: 16),

              // Plus
              PricingCard(
                planName: 'Plus Plan',
                price: '₹129/year',
                features: const [
                  'MHT CET PYQs Access: Unlimited',
                  'Board PYQs: Yes',
                  'Chapter-wise Notes: Yes',
                  'Topper Notes Download: Yes',
                  'Mock Tests per Subject: 2',
                  'Full Mock Test Series: No',
                  'Topper Profiles: Read-only',
                  'Performance Tracking: Yes',
                ],
                isCurrent: currentLevel == plusLevel,
                isDisabled: plusDisabled && currentLevel != plusLevel,
                disabledReason: 'Downgrade not available',
                onPurchase: () => _startPaidPlan(
                  context,
                  planCode: 'Plus',
                  rupees: 129,
                ),
                buttonText:
                    currentLevel == plusLevel ? 'Current Plan' : 'Purchase Now',
                buttonColor: Colors.blue,
              ),
              const SizedBox(height: 16),

              // Pro
              PricingCard(
                planName: 'Pro Plan',
                price: '₹149/year',
                features: const [
                  'Everything in Plus',
                  'Board PYQs: Yes',
                  'Full Mock Test Series: Yes',
                  'Topper Profiles: Full Access',
                  'Priority Features: Yes',
                  'Performance Tracking: Yes',
                ],
                isCurrent: currentLevel == proLevel,
                isDisabled: proDisabled && currentLevel != proLevel,
                onPurchase: () => _startPaidPlan(
                  context,
                  planCode: 'Pro',
                  rupees: 149,
                ),
                buttonText:
                    currentLevel == proLevel ? 'Current Plan' : 'Purchase Now',
                buttonColor: Colors.purple,
              ),

              const SizedBox(height: 32),
              const Text(
                'Accepted Payment Methods:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '• UPI (PhonePe, Google Pay, Paytm)\n'
                '• Debit/Credit Cards\n'
                '• Net Banking\n'
                '• Wallets',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PricingCard extends StatelessWidget {
  final String planName;
  final String price;
  final List<String> features;
  final VoidCallback onPurchase;
  final String buttonText;
  final Color buttonColor;
  final bool isCurrent;

  // NEW:
  final bool isDisabled;
  final String? disabledReason;

  const PricingCard({
    super.key,
    required this.planName,
    required this.price,
    required this.features,
    required this.onPurchase,
    required this.buttonText,
    required this.buttonColor,
    required this.isCurrent,
    this.isDisabled = false,
    this.disabledReason,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = isCurrent || isDisabled;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCurrent
              ? [Colors.blue.shade100, Colors.blue.shade50]
              : [Colors.white, Colors.grey.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isCurrent
            ? Border.all(color: Colors.blue.shade700, width: 2)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(
              planName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            if (isCurrent)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Current Plan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (isDisabled && (disabledReason ?? '').isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade500,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  disabledReason!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 8),
          Text(
            price,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Features:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 22,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: disabled ? null : onPurchase,
            style: ElevatedButton.styleFrom(
              backgroundColor: disabled ? Colors.grey.shade400 : buttonColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 14,
              ),
              elevation: disabled ? 0 : 5,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
