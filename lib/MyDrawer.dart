import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cet_verse/state/AuthProvider.dart'; // Adjust path as needed

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Access AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);

    return Drawer(
      child: Column(
        children: [
          // Drawer Header with Gradient Background and 100% Width
          DrawerHeader(
            padding: EdgeInsets.zero,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 7, 45, 57),
                  Color.fromARGB(255, 20, 60, 80),
                ],
              ),
            ),
            child: SizedBox.expand(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Image
                    const CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      backgroundImage: AssetImage('assets/promogirl.png'),
                    ),
                    const SizedBox(height: 16),
                    // User Name (from AuthProvider)
                    Text(
                      authProvider.currentUser != null
                          ? "Hello, ${authProvider.currentUser!.name}!"
                          : "Hello, User!",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // User Email or Phone Number (from AuthProvider)
                    Text(
                      authProvider.currentUser != null
                          ? authProvider.currentUser!.email ??
                              authProvider.userPhoneNumber ??
                              "No email/phone"
                          : "user@example.com",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Drawer Items
          Expanded(
            child: ListView(
              children: [
                _buildDrawerItem(
                  context,
                  icon: Icons.home_filled,
                  title: "Home",
                  onTap: () => _navigateToPage(context, 'Home'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.attach_money,
                  title: "Pricing Plans",
                  onTap: () => _navigateToPage(context, 'Pricing Plans'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.share,
                  title: "Share & Earn",
                  onTap: () => _navigateToPage(context, 'Share & Earn'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.analytics_outlined,
                  title: "My analysis",
                  onTap: () => _navigateToPage(context, 'My analysis'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.shopping_bag_outlined,
                  title: "My purchases",
                  onTap: () => _navigateToPage(context, 'My purchases'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.help_outline,
                  title: "Need Help",
                  onTap: () => _navigateToPage(context, 'Need Help'),
                ),
                _buildDrawerItem(
                  context,
                  icon: Icons.settings,
                  title: "Settings",
                  onTap: () => _navigateToPage(context, 'Settings'),
                ),
              ],
            ),
          ),
          // Divider and Styled Logout Button
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () {
                // Logout functionality
                //  authProvider.logout(); // Call logout method
                Navigator.pop(context); // Close the drawer
                // Optionally navigate to login screen
                // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                minimumSize: const Size.fromHeight(50), // Full-width
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // Close the drawer
        onTap();
      },
    );
  }

  void _navigateToPage(BuildContext context, String label) {
    switch (label) {
      case 'Home':
        // Navigator.push(context, MaterialPageRoute(builder: (_) => HomePage()));
        break;
      case 'Pricing Plans':
        // Navigator.push(context, MaterialPageRoute(builder: (_) => PricingPlansPage()));
        break;
      case 'Share & Earn':
        // Navigator.push(context, MaterialPageRoute(builder: (_) => ShareAndEarnPage()));
        break;
      case 'My analysis':
        // Navigator.push(context, MaterialPageRoute(builder: (_) => MyAnalysisPage()));
        break;
      case 'My purchases':
        // Navigator.push(context, MaterialPageRoute(builder: (_) => MyPurchasesPage()));
        break;
      case 'Need Help':
        // Navigator.push(context, MaterialPageRoute(builder: (_) => HelpPage()));
        break;
      case 'Settings':
        // Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage()));
        break;
      default:
        break;
    }
  }
}
