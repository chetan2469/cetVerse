import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/payentgetway/PaymentPage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PricingPage extends StatelessWidget {
  const PricingPage({super.key});

  // Function to handle purchase and update Firestore
  Future<void> _handlePurchase(
      BuildContext context, String planName, double amount) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userPhoneNumber = authProvider.userPhoneNumber;

    if (userPhoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to purchase a plan')),
      );
      return;
    }

    // Simulate payment initiation (replace with actual payment gateway integration)
    try {
      // Placeholder for payment gateway logic (e.g., Razorpay)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Processing purchase for $planName plan (₹$amount)')),
      );

      // Update planType in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userPhoneNumber)
          .set(
        {
          'subscription': {'planType': planName}
        },
        SetOptions(merge: true),
      );

      // Update local AuthProvider
      await authProvider.fetchUserData(userPhoneNumber);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$planName plan activated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Purchase failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentPlan = authProvider.getPlanType ?? 'Starter';

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
              // Starter Plan
              PricingCard(
                planName: 'Starter Plan',
                price: '₹0',
                features: const [
                  'Limited access to MHT CET PYQs',
                  '2 Free Mock Tests (Each Subject)',
                  'Browse Topper Profiles (read-only)',
                ],
                isCurrent: currentPlan == 'Starter',
                onPurchase: () {
                  _handlePurchase(context, 'Starter', 0);
                },
                buttonText:
                    currentPlan == 'Starter' ? 'Current Plan' : 'Get Started',
                buttonColor: Colors.green,
              ),
              const SizedBox(height: 16),
              // Plus Plan
              PricingCard(
                planName: 'Plus Plan',
                price: '₹129/year',
                features: const [
                  'Full access to MHT CET PYQs',
                  'Access to all Chapter-wise Notes',
                  'Topper Notes & Profiles (with downloads)',
                  'Full Mock Test Series',
                  'Performance Tracking',
                ],
                isCurrent: currentPlan == 'Plus',
                onPurchase: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PaymentPage(planName: 'Plus', amount: 129),
                    ),
                  );
                },
                buttonText:
                    currentPlan == 'Plus' ? 'Current Plan' : 'Purchase Now',
                buttonColor: Colors.blue,
              ),
              const SizedBox(height: 16),
              // Pro Plan
              PricingCard(
                planName: 'Pro Plan',
                price: '₹149/year',
                features: const [
                  'Everything in Plus Plan',
                  'Solved Board PYQs (HSC Board, Handwritten)',
                  'Priority Access to New Features',
                ],
                isCurrent: currentPlan == 'Pro',
                onPurchase: () {
                  _handlePurchase(context, 'Pro', 149);
                },
                buttonText:
                    currentPlan == 'Pro' ? 'Current Plan' : 'Purchase Now',
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

  const PricingCard({
    super.key,
    required this.planName,
    required this.price,
    required this.features,
    required this.onPurchase,
    required this.buttonText,
    required this.buttonColor,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                  ),
              ],
            ),
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
              onPressed: isCurrent ? null : onPurchase,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrent ? Colors.grey.shade400 : buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                elevation: isCurrent ? 0 : 5,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
