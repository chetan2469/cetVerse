import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service and Privacy Policy'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Container(
        color: Colors.grey.shade50,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'CETverse Terms of Service and Privacy Policy',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Last Updated: April 12, 2025',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 1. Introduction & Agreement to Terms
              const Text(
                '1. Introduction & Agreement to Terms',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Divider(color: Colors.grey, thickness: 1),
              const SizedBox(height: 8),
              const Text(
                'Welcome to CETverse ("we," "us," or "our"). We provide an educational platform designed to assist students preparing for the MHT-CET and other examinations. These Terms of Service ("Terms") govern your access to and use of the CETverse mobile application, our website, and any content, or services (collectively, the "Services") offered by us. By creating an account, purchasing a subscription, or otherwise accessing or using our Services, you agree to be bound by these Terms and our Privacy Policy. If you do not agree to these Terms, you may not access or use our Services.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // 2. Privacy Policy
              const Text(
                '2. Privacy Policy',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Divider(color: Colors.grey, thickness: 1),
              const SizedBox(height: 8),
              const Text(
                'Our commitment to your privacy is paramount. This section outlines how we collect, use, and protect your information.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '- Information We Collect: We may collect personal information you provide to us, such as your name, email address, and academic details. We also collect usage data, such as test scores, performance analytics, and device information to enhance our Services.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '- How We Use Your Data: Your data is used to personalize your learning experience, provide performance tracking, process transactions, communicate with you, and improve the overall functionality of the App.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '- Data Security: We implement industry-standard security measures, including HTTPS encryption, to protect your data from unauthorized access, alteration, or disclosure.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '- Data Sharing: We do not sell or rent your personal data. It may be shared with third-party service providers only to facilitate our Services (e.g., payment processing), or if required by law.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '- Your Data Rights & Deletion: You have the right to access, correct, or request the deletion of your personal data. Data deletion requests can be submitted at the designated deletion request page. We will process your request in accordance with applicable laws.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 3. Intellectual Property and Content Ownership
              const Text(
                '3. Intellectual Property and Content Ownership',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Divider(color: Colors.grey, thickness: 1),
              const SizedBox(height: 8),
              const Text(
                'All materials within the Services, including but not limited to text, graphics, logos, software, question banks, notes, and user interface designs (the "Content"), are the property of CETverse or its licensors and are protected by copyright, trademark, and other intellectual property laws.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '- Limited License: We grant you a limited, non-exclusive, non-transferable, and revocable license to access and use the Services for your personal, non-commercial educational purposes, contingent on your compliance with these Terms.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '- Usage Restrictions: You agree not to reproduce, duplicate, copy, sell, resell, distribute, or otherwise exploit any portion of the Service, use of the Service, or access to the Service without express written permission from us.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. Subscriptions, Pricing, and Payment
              const Text(
                '4. Subscriptions, Pricing, and Payment',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Divider(color: Colors.grey, thickness: 1),
              const SizedBox(height: 8),
              const Text(
                'CETverse offers various tiers of access to its Services:',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 110,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: const [
                        Text(
                          'Starter Plan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '₹0',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Limited access to MHT CET PYQs, 2 Free Mock Tests (Each Subject), Browse Topper Profiles (read-only).',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 110,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      children: const [
                        Text(
                          'Plus Plan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '₹129 /year',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Full access to MHT CET PYQs, Access to all Chapter-wise Notes, Topper Notes & Profiles (with downloads), Full Mock Test Series, Performance Tracking.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 110,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: const [
                        Text(
                          'Pro Plan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '₹149 /year',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Everything in Plus, plus Solved Board PYQs (HSC Board Questions with Solutions & Handwritten), and priority access to new features.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '- Payment and Billing: By purchasing a subscription, you authorize us to charge your chosen payment provider. All payments are handled through secure third-party payment gateways.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '- Renewals: Subscriptions are for a fixed term (e.g., one year) and do not automatically renew. You will need to purchase a new subscription to continue access after the term expires.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '- Refunds: All purchases are final and non-refundable.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 5. User Conduct and Responsibilities
              const Text(
                '5. User Conduct and Responsibilities',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Divider(color: Colors.grey, thickness: 1),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '- Account Security: You are responsible for safeguarding your account credentials. You agree to notify us immediately of any unauthorized use of your account.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '- Acceptable Use: You agree not to use the Services to engage in any activity that is illegal, harmful, or fraudulent. You shall not attempt to reverse-engineer, decompile, or otherwise access the source code of the App.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '- Compliance: You agree to use the Services in compliance with all applicable local, state, national, and international laws, including the Google Play Store Developer Policies.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 6. Disclaimers and Limitation of Liability
              const Text(
                '6. Disclaimers and Limitation of Liability',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Divider(color: Colors.grey, thickness: 1),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '- "AS IS" Service: The Services are provided "as is" and "as available" without any warranties of any kind, express or implied. While we strive for accuracy, we do not warrant that the content is accurate, complete, reliable, or error-free.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '- Limitation of Liability: To the fullest extent permitted by law, CETverse and its affiliates, officers, employees, and agents will not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of profits or revenues, whether incurred directly or indirectly, or any loss of data, use, goodwill, or other intangible losses, resulting from your use of the Services.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 7. Termination
              const Text(
                '7. Termination',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Divider(color: Colors.grey, thickness: 1),
              const SizedBox(height: 8),
              const Text(
                'We reserve the right to suspend or terminate your access to the Services at our sole discretion, without notice or liability, for any reason, including but not limited to a breach of these Terms. Upon termination, your right to use the Services will immediately cease.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // 8. Changes to Terms
              const Text(
                '8. Changes to Terms',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Divider(color: Colors.grey, thickness: 1),
              const SizedBox(height: 8),
              const Text(
                'We may modify these Terms at any time. We will provide notice of any material changes by posting the new Terms within the App or on our website. Your continued use of the Services after such changes constitutes your acceptance of the new Terms.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // 9. Governing Law and Dispute Resolution
              const Text(
                '9. Governing Law and Dispute Resolution',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Divider(color: Colors.grey, thickness: 1),
              const SizedBox(height: 8),
              const Text(
                'These Terms shall be governed by and construed in accordance with the laws of India, without regard to its conflict of law principles. Any dispute arising from these Terms shall be subject to the exclusive jurisdiction of the courts located in Pune, Maharashtra.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // 10. Contact Information
              const Text(
                '10. Contact Information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Divider(color: Colors.grey, thickness: 1),
              const SizedBox(height: 8),
              const Text(
                'If you have any questions about these Terms, please contact us at chedotech@gmail.com.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const Text(
                'Trade name - GANESH BABU GHOLAVE',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
