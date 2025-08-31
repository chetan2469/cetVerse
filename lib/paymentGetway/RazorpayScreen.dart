import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayScreen extends StatefulWidget {
  const RazorpayScreen({super.key});

  @override
  State<RazorpayScreen> createState() => _RazorpayScreenState();
}

class _RazorpayScreenState extends State<RazorpayScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear(); // remove all listeners
    super.dispose();
  }

  // 1) (Recommended) Fetch order from your backend, then open checkout
  Future<void> payWithOrder() async {
    // TODO: call your API that creates an order on Razorpay and returns {orderId, amount, currency}
    final orderId = 'order_xxx_from_server';
    final amountInPaise = 1000; // ₹10.00
    final options = {
      'key': 'rzp_test_xxx', // use LIVE key in production
      'amount': amountInPaise, // in the smallest currency unit
      'currency': 'INR',
      'name': 'Your Brand',
      'description': 'Demo payment',
      'order_id': orderId, // required when using Orders API
      'timeout': 60, // seconds
      'prefill': {'contact': '9999999999', 'email': 'user@example.com'},
      'retry': {'enabled': true, 'max_count': 4}
    };
    _razorpay.open(options);
  }

  // 2) (For quick local test only) Open without order_id
  Future<void> quickPay() async {
    final options = {
      'key': 'rzp_test_xxx',
      'amount': 1000, // ₹10.00
      'currency': 'INR',
      'name': 'Your Brand',
      'description': 'No-order quick test',
      'prefill': {'contact': '9999999999', 'email': 'user@example.com'}
    };
    _razorpay.open(options);
  }

  void _onSuccess(PaymentSuccessResponse r) {
    // r.orderId, r.paymentId, r.signature (when order used)
    // TODO: call your server to verify signature (mandatory)
    debugPrint('SUCCESS: ${r.paymentId}');
  }

  void _onError(PaymentFailureResponse r) {
    debugPrint('ERROR: ${r.code} ${r.message}');
  }

  void _onExternalWallet(ExternalWalletResponse r) {
    debugPrint('EXTERNAL_WALLET: ${r.walletName}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Razorpay Demo')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ElevatedButton(
              onPressed: payWithOrder, child: const Text('Pay (Order Flow)')),
          const SizedBox(height: 12),
          OutlinedButton(
              onPressed: quickPay, child: const Text('Quick Test (No Order)')),
        ]),
      ),
    );
  }
}
