import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage>
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

  Future<void> _launchEmail() async {
    final uri =
        Uri.parse('mailto:cetverse@gmail.com?subject=Privacy Policy Inquiry');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      _buildLastUpdated(screenWidth),
                      SizedBox(height: screenHeight * 0.02),
                      ...buildPolicySections(screenWidth),
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
          'Terms & Privacy',
          style: GoogleFonts.poppins(
            fontSize: 18,
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
            Colors.indigo[600]!,
            Colors.blue[600]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.security,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Terms of Service & Privacy Policy',
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.055,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Your privacy and trust are important to us.\nLearn how we protect your data and your rights.',
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

  Widget _buildLastUpdated(double screenWidth) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: Colors.amber[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Updated',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber[800],
                  ),
                ),
                Text(
                  'April 12, 2025',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.amber[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> buildPolicySections(double screenWidth) {
    final sections = [
      {
        'title': '1. Introduction & Agreement',
        'icon': Icons.handshake,
        'color': Colors.blue,
        'content':
            'Welcome to CETverse ("we," "us," or "our"). We provide an educational platform designed to assist students preparing for the MHT-CET and other examinations. These Terms of Service ("Terms") govern your access to and use of the CETverse mobile application, our website, and any content, or services (collectively, the "Services") offered by us. By creating an account, purchasing a subscription, or otherwise accessing or using our Services, you agree to be bound by these Terms and our Privacy Policy.',
      },
      {
        'title': '2. Privacy & Data Protection',
        'icon': Icons.privacy_tip,
        'color': Colors.green,
        'content':
            'Our commitment to your privacy is paramount. This section outlines how we collect, use, and protect your information.',
        'subSections': [
          'Information We Collect: Personal information you provide, usage data, test scores, performance analytics, and device information.',
          'How We Use Your Data: Personalize learning experience, provide performance tracking, process transactions, and improve functionality.',
          'Data Security: Industry-standard security measures including HTTPS encryption to protect your data.',
          'Data Sharing: We do not sell personal data. May be shared with service providers or if required by law.',
          'Your Rights: Access, correct, or request deletion of your personal data through our deletion request page.',
        ],
      },
      {
        'title': '3. Intellectual Property',
        'icon': Icons.copyright,
        'color': Colors.purple,
        'content':
            'All materials within the Services, including text, graphics, logos, software, question banks, notes, and user interface designs are the property of CETverse or its licensors and are protected by intellectual property laws.',
        'subSections': [
          'Limited License: Non-exclusive, non-transferable license for personal, non-commercial educational purposes.',
          'Usage Restrictions: No reproduction, copying, selling, or distribution without express written permission.',
        ],
      },
      {
        'title': '4. Subscription Plans',
        'icon': Icons.card_membership,
        'color': Colors.orange,
        'content': 'CETverse offers various tiers of access to its Services:',
        'isPlansSection': true,
      },
      {
        'title': '5. User Conduct',
        'icon': Icons.verified_user,
        'color': Colors.teal,
        'content': 'Guidelines for responsible use of our services.',
        'subSections': [
          'Account Security: Safeguard your credentials and notify us of unauthorized use.',
          'Acceptable Use: No illegal, harmful, or fraudulent activities. No reverse-engineering attempts.',
          'Compliance: Use Services in compliance with all applicable laws and Google Play Store policies.',
        ],
      },
      {
        'title': '6. Disclaimers & Liability',
        'icon': Icons.warning,
        'color': Colors.red,
        'content':
            'Important limitations and disclaimers regarding our services.',
        'subSections': [
          '"AS IS" Service: Services provided without warranties. We strive for accuracy but don\'t warrant error-free content.',
          'Limitation of Liability: Not liable for indirect, incidental, or consequential damages, loss of profits, or data.',
        ],
      },
      {
        'title': '7. Termination',
        'icon': Icons.exit_to_app,
        'color': Colors.grey,
        'content':
            'We reserve the right to suspend or terminate your access to the Services at our sole discretion, without notice or liability, for any reason, including but not limited to a breach of these Terms. Upon termination, your right to use the Services will immediately cease.',
      },
      {
        'title': '8. Changes to Terms',
        'icon': Icons.update,
        'color': Colors.indigo,
        'content':
            'We may modify these Terms at any time. We will provide notice of material changes by posting new Terms within the App. Your continued use constitutes acceptance of the new Terms.',
      },
      {
        'title': '9. Governing Law',
        'icon': Icons.gavel,
        'color': Colors.brown,
        'content':
            'These Terms shall be governed by the laws of India, without regard to conflict of law principles. Any disputes shall be subject to the exclusive jurisdiction of courts in Pune, Maharashtra.',
      },
    ];

    // Convert sections to widgets
    List<Widget> sectionWidgets = sections.map((section) {
      return Container(
        margin:
            EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: 8),
        child: section['isPlansSection'] == true
            ? _buildPlansSection(section, screenWidth)
            : _buildPolicySection(section, screenWidth),
      );
    }).toList();

    // Add contact section
    sectionWidgets.add(_buildContactSection(screenWidth));

    return sectionWidgets;
  }

  Widget _buildPolicySection(Map<String, dynamic> section, double screenWidth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (section['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    section['icon'] as IconData,
                    color: section['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    section['title'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                    section['content'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),
                  if (section['subSections'] != null) ...[
                    const SizedBox(height: 16),
                    ...(section['subSections'] as List<String>)
                        .map((subSection) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: section['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                subSection,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF374151),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlansSection(Map<String, dynamic> section, double screenWidth) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.card_membership,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    section['title'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              section['content'] as String,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _buildPlanCard(
                    'Nova Plan',
                    '₹0',
                    'Limited MHT CET PYQs, 2 Free Mock Tests, Browse Topper Profiles (read-only)',
                    Colors.green),
                const SizedBox(height: 12),
                _buildPlanCard(
                    'Orbit Plan',
                    '₹399/year',
                    'Full MHT CET PYQs, Chapter-wise Notes, Topper Notes & Profiles, Full Mock Tests, Performance Tracking',
                    Colors.blue),
                const SizedBox(height: 12),
                _buildPlanCard(
                    'Galaxy Plan',
                    '₹449/year',
                    'Everything in Orbit, Solved Board PYQs, Priority access to new features',
                    Colors.purple),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPolicyPoint(
                      'Payment and Billing: Secure third-party payment gateways handle all transactions.'),
                  _buildPolicyPoint(
                      'Renewals: Fixed-term subscriptions that don\'t auto-renew. Purchase new subscription after expiry.'),
                  _buildPolicyPoint(
                      'Refunds: All purchases are final and non-refundable.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
      String title, String price, String features, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Text(
                price,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            features,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF374151),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(double screenWidth) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[50]!, Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _launchEmail,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[400]!, Colors.blue[600]!],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.contact_support,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Questions About Our Terms?',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Contact us for any questions about these terms or privacy policy',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Trade Name: GANESH BABU GHOLAVE',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.touch_app,
                        size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Text(
                      'Tap to send email',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
