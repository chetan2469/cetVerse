import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RazorpayQuickPayPage extends StatefulWidget {
  const RazorpayQuickPayPage({
    super.key,
    required this.mobile,
    required this.priceRupees,
    required this.planName,
    this.customerEmail,
    this.displayName = 'CET Verse',
  });

  final String mobile;
  final num priceRupees;
  final String planName;
  final String? customerEmail;
  final String displayName;

  @override
  State<RazorpayQuickPayPage> createState() => _RazorpayQuickPayPageState();
}

class _RazorpayQuickPayPageState extends State<RazorpayQuickPayPage>
    with TickerProviderStateMixin {
  late Razorpay _razorpay;
  bool _busy = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const String _razorpayKeyId = 'rzp_live_RBPUYyCmLULAgS';

  int get _amountInPaise => (widget.priceRupees * 100).round();

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    // Animation setup
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  // [Keep your existing _featuresForPlan and _subscriptionForPlan methods]
  Map<String, dynamic> _featuresForPlan(String plan) {
    switch (plan) {
      case 'Plus':
        return {
          'mhtCetPyqsAccess': 'full',
          'boardPyqsAccess': true,
          'chapterWiseNotesAccess': true,
          'topperNotesDownload': true,
          'mockTestsPerSubject': 2,
          'fullMockTestSeries': false,
          'topperProfilesAccess': 'read-only',
          'performanceTracking': true,
          'priorityFeatureAccess': false,
        };
      case 'Pro':
        return {
          'mhtCetPyqsAccess': 'full',
          'boardPyqsAccess': true,
          'chapterWiseNotesAccess': true,
          'topperNotesDownload': true,
          'mockTestsPerSubject': 0,
          'fullMockTestSeries': true,
          'topperProfilesAccess': 'full',
          'performanceTracking': true,
          'priorityFeatureAccess': true,
        };
      case 'Starter':
      default:
        return {
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
    }
  }

  Map<String, dynamic> _subscriptionForPlan(String plan, num amountRupees) {
    final now = DateTime.now();
    DateTime? end;
    if (plan == 'Plus' || plan == 'Pro') {
      end = DateTime(now.year + 1, now.month, now.day);
    }
    return {
      'planType': plan,
      'status': 'active',
      'amountPaid': amountRupees,
      'paymentMethod': 'razorpay',
      'startDate': FieldValue.serverTimestamp(),
      'endDate': end,
    };
  }

  Color get _planColor {
    switch (widget.planName.toLowerCase()) {
      case 'starter':
        return Colors.blue;
      case 'plus':
        return Colors.purple;
      case 'pro':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData get _planIcon {
    switch (widget.planName.toLowerCase()) {
      case 'starter':
        return Icons.rocket_launch;
      case 'plus':
        return Icons.star;
      case 'pro':
        return Icons.diamond;
      default:
        return Icons.workspace_premium;
    }
  }

  List<String> get _planFeatures {
    switch (widget.planName.toLowerCase()) {
      case 'starter':
        return [
          '1 Mock Test per Subject',
          'Performance Tracking',
          'Limited PYQ Access'
        ];
      case 'plus':
        return [
          '2 Mock Tests per Subject',
          'Full PYQ Access',
          'Chapter Notes',
          'Board PYQs'
        ];
      case 'pro':
        return [
          'Unlimited Mock Tests',
          'Full Mock Test Series',
          'Priority Support',
          'All Features Unlocked'
        ];
      default:
        return [];
    }
  }

  Future<void> _openCheckout() async {
    if (_amountInPaise <= 0) {
      _showErrorDialog(
          'Invalid Amount', 'The payment amount is invalid. Please try again.');
      Navigator.pop(context, {'ok': false, 'reason': 'invalid_amount'});
      return;
    }

    setState(() => _busy = true);

    try {
      final options = {
        'key': _razorpayKeyId,
        'amount': _amountInPaise,
        'currency': 'INR',
        'name': widget.displayName,
        'description': '${widget.planName} Plan Subscription',
        'timeout': 300,
        'retry': {'enabled': true, 'max_count': 4},
        'prefill': {
          'contact': widget.mobile,
          'email': widget.customerEmail ?? 'user@example.com',
        },
        'theme': {
          'color': _planColor.value.toRadixString(16).substring(2),
        },
      };
      _razorpay.open(options);
    } catch (e) {
      _showErrorDialog(
          'Payment Error', 'Unable to open payment gateway. Please try again.');
      Navigator.pop(context, {'ok': false, 'reason': 'open_failed'});
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.error_outline, color: Colors.red, size: 48),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String paymentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Payment Successful!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Your ${widget.planName} plan has been activated successfully.'),
            const SizedBox(height: 8),
            Text(
              'Payment ID: $paymentId',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, {
                'ok': true,
                'paymentId': paymentId,
                'planName': widget.planName,
                'amount': widget.priceRupees,
              }); // Close payment page
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  // [Keep your existing payment callback methods but update success to show dialog]
  Future<void> _onPaymentSuccess(PaymentSuccessResponse r) async {
    final paymentId =
        r.paymentId ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}';
    try {
      // Your existing Firestore logic...
      final paymentDoc = {
        'status': 'success',
        'provider': 'razorpay',
        'flow': 'frontend_only',
        'planName': widget.planName,
        'amountRupees': widget.priceRupees,
        'amountPaise': _amountInPaise,
        'currency': 'INR',
        'paymentId': r.paymentId,
        'orderId': r.orderId,
        'signature': r.signature,
        'mobile': widget.mobile,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.mobile)
          .collection('paymentHistory')
          .doc(paymentId)
          .set(paymentDoc, SetOptions(merge: true));

      final subscription =
          _subscriptionForPlan(widget.planName, widget.priceRupees);
      final features = _featuresForPlan(widget.planName);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.mobile)
          .set({'subscription': subscription, 'features': features},
              SetOptions(merge: true));

      if (!mounted) return;
      _showSuccessDialog(paymentId);
    } catch (e) {
      _showErrorDialog('Database Error',
          'Payment successful but failed to update records. Contact support.');
    }
  }

  Future<void> _onPaymentError(PaymentFailureResponse r) async {
    try {
      // Your existing error logging...
      final docId = 'fail_${DateTime.now().millisecondsSinceEpoch}';
      final data = {
        'status': 'failed',
        'provider': 'razorpay',
        'flow': 'frontend_only',
        'planName': widget.planName,
        'amountRupees': widget.priceRupees,
        'amountPaise': _amountInPaise,
        'currency': 'INR',
        'mobile': widget.mobile,
        'errorCode': r.code,
        'errorMessage': r.message,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.mobile)
          .collection('paymentHistory')
          .doc(docId)
          .set(data, SetOptions(merge: true));
    } catch (_) {}

    if (!mounted) return;
    _showErrorDialog('Payment Failed',
        r.message ?? 'Payment was cancelled or failed. Please try again.');
    Navigator.pop(context, {'ok': false, 'reason': 'failed_or_timeout'});
  }

  void _onExternalWallet(ExternalWalletResponse r) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Redirecting to ${r.walletName}...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountStr = '₹${widget.priceRupees.toStringAsFixed(2)}';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: const Text('Complete Payment'),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_planColor, _planColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _planColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child:
                                Icon(_planIcon, color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${widget.planName} Plan',
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.displayName,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        amountStr,
                        style: theme.textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.planName != 'Starter') ...[
                        const SizedBox(height: 8),
                        Text(
                          'Valid for 1 year',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Features Section
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What\'s Included',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ..._planFeatures
                          .map((feature) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        feature,
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Payment Details
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Payment Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _openCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _planColor,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: _planColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _busy
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text('Processing...'),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.security),
                              const SizedBox(width: 8),
                              Text(
                                'Pay $amountStr Securely',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Security Notice
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '256-bit SSL secured payment powered by Razorpay',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
