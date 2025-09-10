import 'package:cet_verse/features/courses/chapters.dart';
import 'package:cet_verse/features/courses/notes/notes_page.dart';
import 'package:cet_verse/screens/pricing_page.dart';
import 'package:flutter/material.dart';
import 'package:cet_verse/ui/theme/constants.dart';
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
  void _upsell(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PricingPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Access control gates
    final notesAllowed = auth.chapterWiseNotesAccess;
    final testsAllowed =
        auth.fullMockTestSeries || auth.mockTestsPerSubject > 0;
    final testsFooter = auth.fullMockTestSeries
        ? 'Unlimited tests available'
        : 'First ${auth.mockTestsPerSubject} tests available';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.subject} Practice',
          style: AppTheme.subheadingStyle.copyWith(
            fontSize: 20,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  Text(
                    "Choose Study Method",
                    style: AppTheme.subheadingStyle.copyWith(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildStudyOptions(
                      auth, testsAllowed, testsFooter, notesAllowed),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigoAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.school,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Practice ${widget.subject}',
                    style: AppTheme.subheadingStyle.copyWith(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyOptions(AuthProvider auth, bool testsAllowed,
      String testsFooter, bool notesAllowed) {
    return Column(
      children: [
        _buildOptionCard(
          icon: Icons.quiz,
          title: "Mock Tests",
          description:
              "Attempt full-length PYQ Tests or chapter-wise tests. Track your progress & scores!",
          footer: testsFooter,
          isLocked: !testsAllowed,
          isFirstItem: true,
          onTap: () {
            if (!testsAllowed) {
              _upsell(context, 'Mock tests are available on Plus/Pro plans');
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Chapters(
                  level: widget.level,
                  subject: widget.subject,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _buildOptionCard(
          icon: Icons.menu_book,
          title: "Study Notes",
          description:
              "Access study materials, summaries, and important formula sheets.",
          footer: notesAllowed ? 'Available' : 'Plus/Pro required',
          isLocked: false,
          isFirstItem: false,
          onTap: () {
            if (notesAllowed) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PricingPage()),
              );
            }
            if (!notesAllowed) {
              _upsell(context, 'Notes are available on Plus/Pro plans');
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => NotesPage(
                  level: widget.level,
                  subject: widget.subject,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String description,
    required String footer,
    required bool isLocked,
    required bool isFirstItem,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isLocked ? null : onTap,
        splashColor: Colors.indigoAccent.withOpacity(0.2),
        child: Opacity(
          opacity: isLocked ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isFirstItem
                        ? Colors.indigoAccent
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTheme.subheadingStyle.copyWith(
                                fontSize: 16,
                                color: isLocked ? Colors.grey : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isFirstItem && !isLocked) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'POPULAR',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: AppTheme.captionStyle.copyWith(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isLocked
                              ? Colors.orange.withOpacity(0.1)
                              : Colors.indigoAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          footer,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color:
                                isLocked ? Colors.orange : Colors.indigoAccent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTrailingWidget(isLocked),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingWidget(bool isLocked) {
    if (isLocked) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.lock,
          color: Colors.white,
          size: 20,
        ),
      );
    } else {
      return const Icon(
        Icons.arrow_forward_ios,
        color: Colors.indigoAccent,
        size: 20,
      );
    }
  }
}
