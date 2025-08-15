import 'package:cet_verse/features/courses/pyq/PYQTestNameList.dart';
import 'package:cet_verse/ui/components/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'package:provider/provider.dart';
import 'package:cet_verse/core/auth/AuthProvider.dart';

class PYQTestYear extends StatelessWidget {
  final String pyqType;

  const PYQTestYear({super.key, required this.pyqType});

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final authProvider = Provider.of<AuthProvider>(context);

    return SafeArea(
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: AppTheme.scaffoldBackground,
        appBar: AppBar(
          title: Text(
            'Past Year Questions ( $pyqType )',
            style: AppTheme.subheadingStyle.copyWith(fontSize: 20),
          ),
          elevation: 2,
          backgroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Year",
                style: AppTheme.subheadingStyle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 12),
              _buildYearsColumn(context, authProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearsColumn(BuildContext context, AuthProvider authProvider) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('pyq').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading years...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          print('Firestore error: ${snapshot.error}');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading years: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print('No documents found in pyq collection');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.grey,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No years found in PYQ collection.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        // Fetch all fields and extract unique testYear values
        List<int> years = snapshot.data!.docs
            .map((doc) {
              final testYear = doc['testYear'] as int?;
              final testName = doc['testName'] as String?;
              final group = doc['group'] as String?;
              print(
                  'Fetched doc: testYear: $testYear, testName: $testName, group: $group');
              return testYear ?? 0;
            })
            .where((year) => year != 0)
            .toSet()
            .toList();
        // Sort years in descending order
        years.sort((a, b) => b.compareTo(a));
        print('Fetched years: $years');

        // Determine the current year (latest year)
        int currentYear = years.isNotEmpty ? years.first : 0;

        return Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: years.length,
              itemBuilder: (context, index) {
                final year = years[index];
                final displayTitle = 'Year $year';
                final isCurrentYear = year == currentYear;
                final isStarterPlan = authProvider.getPlanType == 'Starter';
                final isAdmin = authProvider.userType == 'Admin';

                // Disable non-current years for Starter plan
                bool isDisabled = !isCurrentYear && isStarterPlan;

                if (isAdmin) {
                  isDisabled = false;
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildYearCard(
                    context,
                    title: displayTitle,
                    icon: Icons.calendar_month,
                    color: Colors.white,
                    onTap: isDisabled
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PYQTestNameList(
                                  year: year.toString(),
                                  pyqType: pyqType,
                                ),
                              ),
                            );
                          },
                    isDisabled: isDisabled,
                    isFirstItem: index == 0,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildYearCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    bool isDisabled = false,
    bool isFirstItem = false,
  }) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isStarterPlan = authProvider.getPlanType == 'Starter';

    Widget trailingWidget = const SizedBox.shrink(); // Blank by default
    if (isStarterPlan) {
      if (isFirstItem && !isDisabled) {
        trailingWidget = const SizedBox.shrink(); // Blank for current year
      } else if (isDisabled) {
        trailingWidget = Image.asset(
          'assets/crown.png',
          height: 40,
        ); // Crown icon for non-current years
      }
    } else {
      trailingWidget = const Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey,
        size: 20,
      ); // Unlock for other plans
    }

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isDisabled ? 0.8 : 1.0,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(16),
          shadowColor: Colors.black.withOpacity(0.2),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            splashColor: color.withOpacity(0.3),
            highlightColor: Colors.transparent,
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: color, // White background for all years
                borderRadius: BorderRadius.circular(16),
                border: Border.all(),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.25),
                      ),
                      child: Icon(
                        icon,
                        size: 36,
                        color: color,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTheme.subheadingStyle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDisabled ? Colors.grey : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: trailingWidget,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
