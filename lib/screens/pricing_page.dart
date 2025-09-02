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
    required String planCode,
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
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Unlock Your Potential',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
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
          child: Column(
            children: [
              // Header Section - Compact
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    Text(
                      'Choose the perfect plan for your CET preparation',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Plans Section - Horizontal Layout for larger screens, Vertical for smaller
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: screenWidth > 600
                    ? IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                                child: _buildPlanCard(
                                    context, 'Starter', currentLevel)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildPlanCard(
                                    context, 'Plus', currentLevel)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildPlanCard(
                                    context, 'Pro', currentLevel)),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          _buildPlanCard(context, 'Starter', currentLevel),
                          const SizedBox(height: 12),
                          _buildPlanCard(context, 'Plus', currentLevel),
                          const SizedBox(height: 12),
                          _buildPlanCard(context, 'Pro', currentLevel),
                        ],
                      ),
              ),
              // Payment Methods - Compact
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment,
                            color: Colors.blue.shade600, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Accepted Payment Methods',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _buildPaymentChip('UPI', Icons.account_balance_wallet),
                        _buildPaymentChip('Cards', Icons.credit_card),
                        _buildPaymentChip('Net Banking', Icons.account_balance),
                        _buildPaymentChip('Wallets', Icons.wallet),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentChip(String label, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.grey.shade600),
      label: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
      ),
      backgroundColor: Colors.grey.shade100,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildPlanCard(
      BuildContext context, String planType, int currentLevel) {
    final planData = _getPlanData(planType);
    final level = _levelFor(planType);
    final isCurrent = currentLevel == level;
    final isDisabled = currentLevel > level;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCurrent
              ? [Colors.blue.shade100, Colors.blue.shade50]
              : planType == 'Pro'
                  ? [Colors.purple.shade50, Colors.white]
                  : [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: isCurrent
            ? Border.all(color: Colors.blue.shade400, width: 2)
            : planType == 'Pro'
                ? Border.all(color: Colors.purple.shade200, width: 1)
                : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        planData['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        planData['price'],
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: planType == 'Pro'
                              ? Colors.purple.shade600
                              : Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (planType == 'Pro')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'POPULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Features - Compact with icons
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Key Features:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Column(
                  children: planData['features'].map<Widget>((feature) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            feature['available']
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 16,
                            color: feature['available']
                                ? Colors.green.shade600
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              feature['text'],
                              style: TextStyle(
                                fontSize: 12,
                                color: feature['available']
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action Button
            SizedBox(
              width: double.infinity,
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
                      ? Colors.grey.shade300
                      : planType == 'Pro'
                          ? Colors.purple.shade600
                          : planType == 'Plus'
                              ? Colors.blue.shade600
                              : Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: isCurrent || isDisabled ? 0 : 2,
                ),
                child: Text(
                  isCurrent
                      ? 'Current Plan'
                      : isDisabled
                          ? 'Downgrade N/A'
                          : planType == 'Starter'
                              ? 'Get Started'
                              : 'Upgrade Now',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getPlanData(String planType) {
    switch (planType) {
      case 'Starter':
        return {
          'name': 'Starter Plan',
          'price': 'FREE',
          'features': [
            {'text': 'Limited MHT CET PYQs', 'available': true},
            {'text': '1 Mock Test/Subject', 'available': true},
            {'text': 'Basic Performance Track', 'available': true},
            {'text': 'Read-only Topper Profiles', 'available': true},
            {'text': 'Board PYQs Access', 'available': false},
            {'text': 'Chapter Notes Download', 'available': false},
          ]
        };
      case 'Plus':
        return {
          'name': 'Plus Plan',
          'price': '₹129/year',
          'features': [
            {'text': 'Unlimited MHT CET PYQs', 'available': true},
            {'text': 'Board PYQs Access', 'available': true},
            {'text': 'Chapter-wise Notes', 'available': true},
            {'text': 'Topper Notes Download', 'available': true},
            {'text': '2 Mock Tests/Subject', 'available': true},
            {'text': 'Full Mock Test Series', 'available': false},
          ]
        };
      case 'Pro':
        return {
          'name': 'Pro Plan',
          'price': '₹149/year',
          'features': [
            {'text': 'Everything in Plus', 'available': true},
            {'text': 'Full Mock Test Series', 'available': true},
            {'text': 'Complete Topper Profiles', 'available': true},
            {'text': 'Priority Feature Access', 'available': true},
            {'text': 'Advanced Analytics', 'available': true},
            {'text': 'Premium Support', 'available': true},
          ]
        };
      default:
        return {};
    }
  }
}
