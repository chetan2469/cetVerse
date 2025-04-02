import 'package:cet_verse/models/UserModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cet_verse/state/AuthProvider.dart';
import 'package:cet_verse/AboutUsPage.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Settings",
            style:
                GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
        child: Column(
          children: [
            _buildProfileSection(user!),
            const SizedBox(height: 20),
            _buildSettingsOptions(context),
          ],
        ),
      ),
    );
  }

  /// **📌 Profile Section**
  Widget _buildProfileSection(UserModel user) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 35,
          backgroundImage: AssetImage('assets/profile_placeholder.png'),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.name ?? "User Name",
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              user.city ?? "City",
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }

  /// **📌 Settings Options**
  Widget _buildSettingsOptions(BuildContext context) {
    return Column(
      children: [
        _buildSettingsTile(Icons.notifications, "Notifications", () {}),
        _buildSettingsTile(Icons.color_lens, "Theme", () {}),
        _buildSettingsTile(Icons.lock, "Privacy & Security", () {}),
        _buildSettingsTile(Icons.info, "About Us", () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => AboutUsPage()));
        }),
        _buildSettingsTile(Icons.exit_to_app, "Logout", () {
          _showLogoutDialog(context);
        }),
      ],
    );
  }

  /// **📌 Settings Tile**
  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title, style: GoogleFonts.poppins(fontSize: 16)),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
      onTap: onTap,
    );
  }

  /// **📌 Logout Confirmation Dialog**
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text("Logout"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                // Handle logout logic
                Navigator.of(context).pop(); // Close dialog
                // Redirect to login screen (if needed)
              },
            ),
          ],
        );
      },
    );
  }
}
