import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RazorpayQuickPayPage extends StatefulWidget {
  const RazorpayQuickPayPage({
    super.key,
    required this.mobile,
    required this.priceRupees, // e.g. 129 => ₹129.00
    required this.planName, // 'Starter' | 'Plus' | 'Pro'
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

class _RazorpayQuickPayPageState extends State<RazorpayQuickPayPage> {
  late Razorpay _razorpay;
  bool _busy = false;

  // ⚠️ Use TEST key for testing; switch to LIVE when ready.
  static const String _razorpayKeyId = 'rzp_live_RBPUYyCmLULAgS';

  int get _amountInPaise => (widget.priceRupees * 100).round();

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    // Auto-open checkout
    WidgetsBinding.instance.addPostFrameCallback((_) => _openCheckout());
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  // ---- Rules from your CSV (typed to Firestore schema) ----
  Map<String, dynamic> _featuresForPlan(String plan) {
    switch (plan) {
      case 'Plus':
        return {
          // CSV: MHT CET PYQs Access = Unlimited
          'mhtCetPyqsAccess': 'full',
          // CSV: Board PYQs Access = ✅
          'boardPyqsAccess': true,
          // CSV: Chapter Wise Notes Access = ✅
          'chapterWiseNotesAccess': true,
          // CSV: Topper Notes Download = ✅
          'topperNotesDownload': true,
          // CSV: Mock Tests per Subject = 2
          'mockTestsPerSubject': 2,
          // CSV: Full Mock Test Series = ❌
          'fullMockTestSeries': false,
          // CSV: Topper Profiles Access = Read-only
          'topperProfilesAccess': 'read-only',
          // CSV: Performance Tracking = ✅
          'performanceTracking': true,
          // CSV: Priority Feature Access = ❌
          'priorityFeatureAccess': false,
        };
      case 'Pro':
        return {
          'mhtCetPyqsAccess': 'full',
          'boardPyqsAccess': true,
          'chapterWiseNotesAccess': true,
          'topperNotesDownload': true,
          // CSV: Mock Tests per Subject = Unlimited -> keep numeric field 0 to mean "not limited"
          'mockTestsPerSubject': 0,
          'fullMockTestSeries': true,
          'topperProfilesAccess': 'full', // CSV: Full Access
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
          // CSV: Mock Tests per Subject = 1
          'mockTestsPerSubject': 1,
          'fullMockTestSeries': false,
          'topperProfilesAccess': 'read-only',
          'performanceTracking': true, // CSV: ✅ for Starter
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
      'endDate': end, // null for Starter
    };
  }

  // -------------------- Payment flow (frontend-only) --------------------
  Future<void> _openCheckout() async {
    if (_amountInPaise <= 0) {
      _toast('Invalid amount');
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
        'description': '${widget.planName} Plan',
        'timeout': 300,
        'retry': {'enabled': true, 'max_count': 4},
        'prefill': {
          'contact': widget.mobile,
          'email': widget.customerEmail ?? 'user@example.com',
        },
      };
      _razorpay.open(options);
    } catch (e) {
      _toast('Error: $e');
      Navigator.pop(context, {'ok': false, 'reason': 'open_failed'});
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessResponse r) async {
    final paymentId =
        r.paymentId ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}';
    try {
      // 1) Write payment history
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
          .doc(paymentId) // one doc per payment
          .set(paymentDoc, SetOptions(merge: true));

      // 2) Update user doc: subscription + features
      final subscription =
          _subscriptionForPlan(widget.planName, widget.priceRupees);
      final features = _featuresForPlan(widget.planName);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.mobile)
          .set({'subscription': subscription, 'features': features},
              SetOptions(merge: true));

      _toast('Payment Success: $paymentId');
      if (!mounted) return;
      Navigator.pop(context, {
        'ok': true,
        'paymentId': r.paymentId,
        'planName': widget.planName,
        'amount': widget.priceRupees,
      });
    } catch (e) {
      _toast('Saved but DB write failed: $e');
      if (!mounted) return;
      Navigator.pop(context, {'ok': true, 'paymentId': r.paymentId});
    }
  }

  Future<void> _onPaymentError(PaymentFailureResponse r) async {
    try {
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
    _toast('Payment failed or timed out');
    if (!mounted) return;
    Navigator.pop(context, {'ok': false, 'reason': 'failed_or_timeout'});
  }

  void _onExternalWallet(ExternalWalletResponse r) {
    _toast('External wallet: ${r.walletName}');
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final amountStr = '₹${widget.priceRupees.toStringAsFixed(2)}';
    return Scaffold(
      appBar: AppBar(title: const Text('Razorpay Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          ListTile(
              leading: const Icon(Icons.phone),
              title: const Text('Mobile'),
              subtitle: Text(widget.mobile)),
          ListTile(
              leading: const Icon(Icons.workspace_premium),
              title: const Text('Plan'),
              subtitle: Text(widget.planName)),
          ListTile(
              leading: const Icon(Icons.currency_rupee),
              title: const Text('Amount'),
              subtitle: Text(amountStr)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : _openCheckout,
              child: const Text('Pay Now'),
            ),
          ),
          const SizedBox(height: 12),
          if (_busy) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          const Text(
            'Frontend-only: writes paymentHistory and updates features.\n'
            'For production, add backend Orders API + signature verify.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ]),
      ),
    );
  }
}
