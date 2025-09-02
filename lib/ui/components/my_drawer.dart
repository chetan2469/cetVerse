import 'package:cet_verse/core/auth/phone_auth_screen.dart';
import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/screens/NeedHelp.dart';
import 'package:cet_verse/screens/PrivacyPolicyPage.dart';
import 'package:cet_verse/screens/pricing_page.dart';
import 'package:cet_verse/screens/profile_page.dart';
import 'package:cet_verse/ui/components/ProgressPage.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Profile Header
          UserAccountsDrawerHeader(
            accountName: Text(
              authProvider.currentUser != null
                  ? authProvider.currentUser!.name.isNotEmpty
                      ? authProvider.currentUser!.name
                      : 'User'
                  : 'User',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              authProvider.userPhoneNumber ?? 'Phone Number',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            currentAccountPicture: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.indigo.shade300,
              child: Text(
                authProvider.currentUser != null &&
                        authProvider.currentUser!.name.isNotEmpty
                    ? authProvider.currentUser!.name[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.indigo.shade700,
                  authProvider.planType != "Starter"
                      ? Colors.indigo.shade400
                      : Colors.indigo.shade400
                ],
              ),
            ),
          ),
          // Menu Items
          _buildMenuItem(
            context,
            icon: Icons.home_filled,
            title: 'Home',
            onTap: () => _navigateToPage(context, 'Home'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.person,
            title: 'Profile',
            onTap: () => _navigateToPage(context, 'Profile'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.gif_box,
            title: 'Pricing Plans',
            onTap: () => _navigateToPage(context, 'Pricing Plans'),
          ),

          _buildMenuItem(
            context,
            icon: Icons.analytics_outlined,
            title: 'My Analysis',
            onTap: () => _navigateToPage(context, 'My Analysis'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.help_outline,
            title: 'Need Help',
            onTap: () => _navigateToPage(context, 'Need Help'),
          ),
          _buildMenuItem(
            context,
            icon: Icons.policy,
            title: 'Policy',
            onTap: () => _navigateToPage(context, 'Policy'),
          ),
          // _buildMenuItem(
          //   context,
          //   icon: Icons.settings,
          //   title: 'Settings',
          //   onTap: () => _navigateToPage(context, 'Settings'),
          // ),
          // _buildMenuItem(
          //   context,
          //   icon: Icons.share,
          //   title: 'Share & Earn',
          //   onTap: () => _navigateToPage(context, 'Share & Earn'),
          // ),
          // Logout Button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              'Logout',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
            onTap: () {
              authProvider.clearSession();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const PhoneAuthScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor ?? Colors.indigo),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  void _navigateToPage(BuildContext context, String label) {
    Navigator.pop(context); // Close the drawer
    switch (label) {
      case 'Home':
        // Navigate to Home Page
        break;
      case 'Profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePage()),
        );
        break;
      case 'Pricing Plans':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PricingPage()),
        );
        break;
      case 'Share & Earn':
        // Navigate to Share & Earn Page
        break;
      case 'My Analysis':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProgressPage()),
        );
        break;
      case 'My Purchases':
        // Navigate to My Purchases Page
        break;
      case 'Need Help':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NeedHelp()),
        );
        break;
      case 'Policy':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
        );
        break;
      case 'Settings':
        // Navigate to Settings Page
        break;
    }
  }
}
