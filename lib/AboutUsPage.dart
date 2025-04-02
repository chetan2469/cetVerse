import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutUsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("About Us",
            style:
                GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildDescription(),
            const SizedBox(height: 20),
            _buildTeamSection(),
            const SizedBox(height: 20),
            _buildContactSection(),
          ],
        ),
      ),
    );
  }

  /// **📌 About Us Header**
  Widget _buildHeader() {
    return Center(
      child: Column(
        children: [
          Image.asset('assets/logo.png', height: 80),
          const SizedBox(height: 10),
          Text(
            "CET Verse",
            style:
                GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// **📌 App Description**
  Widget _buildDescription() {
    return Text(
      "CET Verse is an advanced learning platform that provides top-quality educational resources, personalized learning experiences, and career guidance for students. "
      "We aim to make learning more interactive, effective, and accessible for everyone.",
      style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
      textAlign: TextAlign.justify,
    );
  }

  /// **📌 Meet Our Team**
  Widget _buildTeamSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Meet Our Team",
            style:
                GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildTeamMember("Chetan Dongarsane", "Founder",
                "assets/profile_placeholder.png"),
            const SizedBox(width: 10),
            _buildTeamMember("Sneha Dongarsane", "Co-Founder",
                "assets/profile_placeholder.png"),
          ],
        ),
      ],
    );
  }

  /// **📌 Team Member Card**
  Widget _buildTeamMember(String name, String role, String imagePath) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundImage: AssetImage(imagePath),
          ),
          const SizedBox(height: 5),
          Text(name,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.bold)),
          Text(role,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  /// **📌 Contact Information**
  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Contact Us",
            style:
                GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildContactRow(Icons.email, "Email", "support@cetverse.com"),
        _buildContactRow(Icons.phone, "Phone", "+91 9876543210"),
        _buildContactRow(
            Icons.location_on, "Address", "Pune, Maharashtra, India"),
      ],
    );
  }

  /// **📌 Contact Row**
  Widget _buildContactRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.bold)),
              Text(value,
                  style:
                      GoogleFonts.poppins(fontSize: 14, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }
}
