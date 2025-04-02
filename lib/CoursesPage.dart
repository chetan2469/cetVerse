import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CoursesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Courses",
            style:
                GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('courses').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No courses available."));
            }
            var courses = snapshot.data!.docs;

            return ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) {
                var course = courses[index].data() as Map<String, dynamic>;
                return _buildCourseCard(course);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.school, color: Colors.blue, size: 30),
        title: Text(course['title'] ?? 'Unknown Course',
            style:
                GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
        subtitle: Text("${course['duration']} | ${course['lessons']} Lessons",
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54)),
        trailing:
            Icon(Icons.arrow_forward_ios, color: Colors.black54, size: 16),
        onTap: () {
          // Navigate to course details (if needed)
        },
      ),
    );
  }
}
