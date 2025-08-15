import 'package:flutter/material.dart';

class NeedHelp extends StatelessWidget {
  const NeedHelp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Need Help?'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Contact Us for Support',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'We’re here to assist you with any questions or issues. Feel free to reach out using the details below. Our team typically responds within 24-48 hours.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Contact Information
              const Text(
                'Contact Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Divider(color: Colors.grey, thickness: 1),
              const SizedBox(height: 12),
              const ListTile(
                leading: Icon(Icons.phone, color: Colors.green),
                title: Text(
                  'Phone: +91-9370048515',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                subtitle: Text(
                  'Available: 9:00 AM - 6:00 PM IST',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const ListTile(
                leading: Icon(Icons.phone, color: Colors.green),
                title: Text(
                  'Alternate: +91-9370048515',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                subtitle: Text(
                  'For urgent queries',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const ListTile(
                leading: Icon(Icons.email, color: Colors.blue),
                title: Text(
                  'Email: support@cetverse.com',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                subtitle: Text(
                  'Response time: 24-48 hours',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),

              // Support Instructions
              const Text(
                'How We Can Help',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Divider(color: Colors.grey, thickness: 1),
              const SizedBox(height: 12),
              const Text(
                '- For technical issues, please describe the problem in detail when contacting us.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                '- For subscription or payment queries, include your order number or phone number linked to the account.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                '- Check our FAQs section in the app for quick solutions to common problems.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // Additional Info
              const Text(
                'Office Address',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Divider(color: Colors.grey, thickness: 1),
              const SizedBox(height: 12),
              const Text(
                'CETverse Support Office\n123 Education Lane, Pune, Maharashtra, India - 411001',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
