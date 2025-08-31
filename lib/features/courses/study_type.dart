import 'package:cet_verse/features/courses/chapters.dart';
import 'package:cet_verse/features/courses/notes/notes_page.dart';
import 'package:cet_verse/screens/pricing_page.dart';
import 'package:flutter/material.dart';
import 'package:cet_verse/ui/theme/constants.dart';

// NEW
import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:provider/provider.dart';

class StudyType extends StatefulWidget {
  final String level;
  final String subject;

  const StudyType({
    super.key,
    required this.level,
    required this.subject,
  });

  @override
  State<StudyType> createState() => _StudyTypeState();
}

class _StudyTypeState extends State<StudyType> {
  Future<void> _refresh() async {
    setState(() {}); // Rebuild UI; hook Firestore if needed
  }

  void _upsell(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const PricingPage()));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Gates
    final notesAllowed = auth.chapterWiseNotesAccess; // Plus/Pro
    final testsAllowed = auth.fullMockTestSeries ||
        auth.mockTestsPerSubject > 0; // Pro or Starter/Plus (N>0)

    final testsFooter = auth.fullMockTestSeries
        ? 'Unlimited tests (Pro)'
        : 'First ${auth.mockTestsPerSubject} tests available';

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
                        "Practice ${widget.subject}",
                        style: AppTheme.subheadingStyle.copyWith(
                          fontSize: 24,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // MOCK TEST
                      _buildOptionCard(
                        context,
                        icon: Icons.list_alt_outlined,
                        title: "Mock Test",
                        description:
                            "Attempt full-length PYQ Tests or chapter-wise tests.\nTrack your progress & scores!",
                        footer: testsFooter,
                        locked: !testsAllowed,
                        onTap: () {
                          if (!testsAllowed) {
                            _upsell(context,
                                'Mock tests are available on Plus/Pro plans');
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Chapters(
                                level: widget.level,
                                subject: widget.subject,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // NOTES
                      _buildOptionCard(
                        context,
                        icon: Icons.menu_book_rounded,
                        title: "Notes",
                        description:
                            "Access study materials, summaries,\nand important formula sheets.",
                        footer:
                            notesAllowed ? 'Available' : 'Locked (Plus/Pro)',
                        locked: !notesAllowed,
                        onTap: () {
                          if (!notesAllowed) {
                            _upsell(context,
                                'Notes are available on Plus/Pro plans');
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotesPage(
                                level: widget.level,
                                subject: widget.subject,
                              ),
                            ),
                          );
                        },
                      ),
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
    bool locked = false,
    String? footer,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      splashColor: Colors.grey.shade200,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          border:
              locked ? Border.all(color: Colors.red.withOpacity(0.4)) : null,
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Icon(icon,
                    color: const Color.fromARGB(255, 33, 32, 32), size: 48),
                if (locked)
                  const Positioned(
                    right: -4,
                    top: -4,
                    child: Icon(Icons.lock, size: 20, color: Colors.red),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTheme.subheadingStyle.copyWith(
                fontSize: 20,
                color: const Color.fromARGB(255, 33, 32, 32),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTheme.captionStyle.copyWith(
                fontSize: 14,
                color: const Color.fromARGB(179, 59, 58, 58),
              ),
              textAlign: TextAlign.center,
            ),
            if (footer != null) ...[
              const SizedBox(height: 10),
              Text(
                footer,
                style: TextStyle(
                  fontSize: 12,
                  color: locked ? Colors.red : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
