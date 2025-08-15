import 'dart:convert';
import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:flutter/material.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

class PaymentPage extends StatefulWidget {
  final String planName;
  final double amount;

  const PaymentPage({super.key, required this.planName, required this.amount});

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? _result;
  String environment = 'SANDBOX'; // Use 'PRODUCTION' for live
  String merchantId = 'M22DBIQG0ELFK';
  String appId = 'SU2506181031118299940925';
  bool enableLogging = true;
  bool _isInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initPhonePeSdk();
  }

  Future<void> _initPhonePeSdk() async {
    try {
      print(
          'Initializing SDK with - env: $environment, appId: $appId, merchantId: $merchantId, logging: $enableLogging');
      bool isInitialized = await PhonePePaymentSdk.init(
        environment,
        appId,
        merchantId,
        enableLogging,
      );
      if (mounted) {
        setState(() {
          _isInitialized = isInitialized;
          _result = 'PhonePe SDK Initialized: $isInitialized';
          print('SDK Initialization Result: $_result');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _result = 'Error initializing SDK: $e';
          print('SDK Initialization Error: $_result');
        });
      }
    }
  }

  Future<String> _createPaymentRequest(String mobileNumber) async {
    Map<String, dynamic> request = {
      'merchantId': 'M22DBIQG0ELFK',
      'merchantTransactionId': 'TXN${DateTime.now().millisecondsSinceEpoch}',
      'amount': (widget.amount * 100).toInt(), // Amount in paise
      'callbackUrl':
          'https://webhook.site/f63d1195-f001-474d-acaa-f7bc4f3b20b1', // Replace with registered URL
      'mobileNumber': mobileNumber,
      'paymentInstrument': {'type': 'PAY_PAGE'},
    };
    return jsonEncode(request);
  }

  String _generateChecksum(String data) {
    const String saltKey =
        'f5f644ea-85a4-403a-bf44-5addefcbf110'; // Client Secret Key
    const String saltIndex = '1';
    const String apiEndpoint = '/pg/v1/pay';
    String dataToHash = '$data$apiEndpoint$saltKey';
    var bytes = utf8.encode(dataToHash);
    var digest = sha256.convert(bytes);
    return '${digest.toString()}###$saltIndex';
  }

  Future<void> _startTransaction() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userPhoneNumber = authProvider.userPhoneNumber;

    if (userPhoneNumber == null) {
      if (mounted) {
        setState(() {
          _result = 'Please log in to proceed with payment';
          _isLoading = false;
        });
      }
      return;
    }

    if (!_isInitialized) {
      if (mounted) {
        setState(() {
          _result = 'SDK not initialized. Please try again.';
          _isLoading = false;
        });
      }
      return;
    }

    try {
      String jsonBody = await _createPaymentRequest(userPhoneNumber);
      String checksum = _generateChecksum(jsonBody);

      // Include checksum in the request body
      Map<String, dynamic> requestWithChecksum = jsonDecode(jsonBody);
      requestWithChecksum['checksum'] = checksum;
      String finalJsonBody = jsonEncode(requestWithChecksum);

      dynamic response = await PhonePePaymentSdk.startTransaction(
        finalJsonBody,
        'cet.com.cet_verse', // Replace with your app scheme
      );

      String transactionResult;
      if (response != null && response['status'] == 'SUCCESS') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userPhoneNumber)
            .update({'subscription.planType': widget.planName});
        await authProvider.fetchUserData(userPhoneNumber);
        transactionResult = 'SUCCESS';
      } else {
        transactionResult =
            'FAILED: ${response?['errorMessage'] ?? 'Unknown error'}';
      }

      if (mounted) {
        setState(() {
          _result = response != null
              ? 'Payment ${response['status'] == 'SUCCESS' ? 'Successful' : 'Failed'}: ${response['transactionId'] ?? response?['errorMessage'] ?? 'N/A'}'
              : 'Transaction incomplete';
          _isLoading = false;
        });
        // Navigator.pop(context, transactionResult);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _result = 'Transaction error: $e';
          _isLoading = false;
        });
        Navigator.pop(context, 'FAILED: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Pay for ${widget.planName} Plan',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Amount: ₹${widget.amount / 100}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _startTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 24,
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        'Proceed to Pay',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
              const SizedBox(height: 20),
              Text(
                _result ?? 'Initializing payment...',
                style: TextStyle(
                  fontSize: 16,
                  color: _result?.contains('Successful') == true
                      ? Colors.green
                      : _result?.contains('Failed') == true
                          ? Colors.red
                          : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
