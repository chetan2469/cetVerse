import 'package:cet_verse/features/courses/pyq/PYQTestQuestionList.dart';
import 'package:cet_verse/features/courses/pyq/Test.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'package:provider/provider.dart';
import 'package:cet_verse/core/auth/AuthProvider.dart';

class PYQTestNameList extends StatefulWidget {
  final String year;
  final String pyqType;

  const PYQTestNameList({super.key, required this.year, required this.pyqType});

  @override
  State<PYQTestNameList> createState() => _PYQTestNameListState();
}

class _PYQTestNameListState extends State<PYQTestNameList> {
  bool isEditingMode = false;

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
            'Tests for Year ${widget.year} ( ${widget.pyqType} )',
            style: AppTheme.subheadingStyle.copyWith(fontSize: 20),
          ),
          elevation: 2,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Select Test",
                style: AppTheme.subheadingStyle.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 12),
              _buildTestsColumn(context, authProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestsColumn(BuildContext context, AuthProvider authProvider) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('pyq')
          .where('testYear', isEqualTo: int.parse(widget.year))
          .where('group', isEqualTo: widget.pyqType.toLowerCase())
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Loading tests...',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
        if (snapshot.hasError) {
          print('Firestore error: ${snapshot.error}');
          if (snapshot.error.toString().contains('index')) {
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
                  const Text(
                    'Indexing error: Please create a composite index for testYear and group in the Firebase Console.',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      print(
                          'Please go to Firebase Console > Firestore Database > Indexes to create the index.');
                    },
                    child: const Text('Create Index'),
                  ),
                ],
              ),
            );
          }
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
                  'Error loading tests: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
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
          print(
              'No tests found for year ${widget.year} and pyqType ${widget.pyqType}');
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
                Text(
                  'No tests found for ${widget.year} (${widget.pyqType}).',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
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

        List<Map<String, dynamic>> tests = snapshot.data!.docs.map((doc) {
          return {
            'testName': doc['testName'] as String,
            'group': doc['group'] as String,
            'testYear': doc['testYear'] as int,
            'docId': doc.id,
          };
        }).toList();

        tests.sort((a, b) => a['testName'].compareTo(b['testName']));

        String currentTest = tests.first['testName'];
        return Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tests.length,
              itemBuilder: (context, index) {
                final test = tests[index];
                final testName = test['testName'];
                final isCurrentTest = testName == currentTest;
                final isStarterPlan = authProvider.getPlanType == 'Starter';

                bool isDisabled = !isCurrentTest && isStarterPlan;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildTestCard(
                    context,
                    testName: testName,
                    docId: test['docId'],
                    index: index + 1, // Pass index starting from 1
                    title: testName,
                    icon: Icons.description,
                    color: Colors.white,
                    onTap: isDisabled
                        ? null
                        : () {
                            if (isEditingMode) {
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Test(
                                    year: widget.year,
                                    pyqType: widget.pyqType,
                                    docId: test['docId'],
                                  ),
                                ),
                              );
                            }
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

  Widget _buildTestCard(
    BuildContext context, {
    required int index, // Added index parameter
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    required testName,
    required docId,
    bool isDisabled = false,
    bool isFirstItem = false,
  }) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isStarterPlan = authProvider.getPlanType == 'Starter';
    final isAdmin = authProvider.userType == 'Admin';

    Widget trailingWidget = const SizedBox.shrink();
    if (isStarterPlan && !isAdmin) {
      if (isFirstItem && !isDisabled) {
        trailingWidget = const SizedBox.shrink();
      } else if (isDisabled) {
        trailingWidget = Image.asset(
          'assets/crown.png',
          height: 40,
        );
      }
    }
    if (isAdmin) {
      trailingWidget = IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PYQTestQuestionList(
                  testName: testName,
                  docId: docId,
                ),
              ),
            );
          },
          icon: Icon(
            Icons.edit,
            color: Colors.grey,
            size: 20,
          ));
    } else {
      trailingWidget = const Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey,
        size: 20,
      );
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
                color: color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '$index', // Display the number
                      style: AppTheme.subheadingStyle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDisabled ? Colors.grey : Colors.black87,
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
