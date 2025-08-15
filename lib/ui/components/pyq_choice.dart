import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/features/courses/pyq/pyq_test_year.dart';
import 'package:cet_verse/ui/components/AddPyq.dart';
import 'package:flutter/material.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'package:provider/provider.dart';

class PYQChoice extends StatefulWidget {
  const PYQChoice({super.key});

  @override
  _PYQChoiceState createState() => _PYQChoiceState();
}

class _PYQChoiceState extends State<PYQChoice> {
  Future<void> _refresh() async {
    setState(() {}); // Rebuilds the UI
    // Add dynamic data fetching here if needed (e.g., Firestore queries)
  }

  @override
  Widget build(BuildContext context) {
    // Access AuthProvider
    final authProvider = Provider.of<AuthProvider>(context);

    // Debug log to check user type
    print('User type: ${authProvider.getUserType}');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                backgroundColor: Colors.white,
                color: Colors.indigoAccent,
                strokeWidth: 3.0,
                displacement: 40.0,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Group Wise Practice",
                        style: AppTheme.subheadingStyle.copyWith(
                          fontSize: 24,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      _buildOptionCard(
                        context,
                        icon: Icons.list_alt_outlined,
                        title: "PCM",
                        description:
                            "Attempt full-length PYQ Tests and \nTrack your progress & scores ! ",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PYQTestYear(
                                pyqType: "PCM",
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildOptionCard(
                        context,
                        icon: Icons.list_alt_outlined,
                        title: "PCB",
                        description:
                            "Attempt full-length PYQ Tests and \nTrack your progress & scores !",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PYQTestYear(
                                pyqType: "PCB",
                              ),
                            ),
                          );
                        },
                      ),
                      // Conditionally show "Add Test" button for Admins
                      const SizedBox(height: 24),
                      if (authProvider.getUserType?.toLowerCase() ==
                          'admin') ...[
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddPyq(),
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Add Test button pressed!'),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Add Test',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ] else ...[
                        // Debug UI for non-Admin users
                        Text(
                          'Admin features not available (User type: ${authProvider.getUserType ?? 'Unknown'})',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      splashColor: Colors.grey.shade200,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black, width: 1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.black, size: 48),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTheme.subheadingStyle.copyWith(
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTheme.captionStyle.copyWith(
                fontSize: 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
