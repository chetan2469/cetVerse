import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/features/courses/pyq/PYQTestQuestionList.dart';
import 'package:cet_verse/features/courses/pyq/tests/new_test_view/test_screen.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

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
    final authProvider = Provider.of<AuthProvider>(context);

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
          'Tests for Year ${widget.year} (${widget.pyqType})',
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
                  Text(
                    "Select Test",
                    style: AppTheme.subheadingStyle.copyWith(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTestsSection(context, authProvider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestsSection(BuildContext context, AuthProvider authProvider) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('pyq')
          .where('testYear', isEqualTo: int.parse(widget.year))
          .where('group', isEqualTo: widget.pyqType.toLowerCase())
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading();
        }
        if (snapshot.hasError) {
          return _buildErrorCard(snapshot.error.toString());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyCard();
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
          children: tests.asMap().entries.map((entry) {
            int index = entry.key;
            var test = entry.value;
            final testName = test['testName'];
            final isCurrentTest = testName == currentTest;
            final isStarterPlan = authProvider.getPlanType == 'Nova';
            bool isDisabled = !isCurrentTest && isStarterPlan;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildTestCard(
                context,
                testName: testName,
                docId: test['docId'],
                index: index + 1,
                isDisabled: isDisabled,
                isFirstItem: index == 0,
                authProvider: authProvider,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return Column(
      children: List.generate(5, (index) => _buildShimmerTestCard(index)),
    );
  }

  Widget _buildShimmerTestCard(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
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
              // Shimmer for test number
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shimmer for test name
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: double.infinity,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Shimmer for description
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 200,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Shimmer for trailing widget
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: 200,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: 150,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    final isIndexError = error.contains('index');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              isIndexError ? 'Database Index Error' : 'Error loading tests',
              style: AppTheme.subheadingStyle.copyWith(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isIndexError
                  ? 'Please create a composite index for testYear and group in Firebase Console'
                  : 'Please try again later',
              style: AppTheme.captionStyle.copyWith(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isIndexError) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () {
                      print(
                          'Please go to Firebase Console > Firestore Database > Indexes to create the index.');
                    },
                    child: Text(
                      'Create Index',
                      style: TextStyle(
                        color: Colors.indigoAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return SizedBox(
      width: MediaQuery.widthOf(context),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
        shadowColor: Colors.grey.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.grey,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                'No tests available',
                style: AppTheme.subheadingStyle.copyWith(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No tests found for ${widget.year} (${widget.pyqType})',
                style: AppTheme.captionStyle.copyWith(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() {}),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestCard(
    BuildContext context, {
    required String testName,
    required String docId,
    required int index,
    required bool isDisabled,
    required bool isFirstItem,
    required AuthProvider authProvider,
  }) {
    final isStarterPlan = authProvider.getPlanType == 'Nova';
    final isAdmin = authProvider.userType == 'Admin';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isDisabled
            ? null
            : () {
                if (isEditingMode) {
                  // Handle editing mode
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TestWrapper(
                        year: widget.year,
                        pyqType: widget.pyqType,
                        docId: docId,
                      ),
                    ),
                  );
                }
              },
        splashColor: Colors.indigoAccent.withOpacity(0.2),
        child: Opacity(
          opacity: isDisabled ? 0.6 : 1.0,
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
                  child: Center(
                    child: Text(
                      '$index',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
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
                              testName,
                              style: AppTheme.subheadingStyle.copyWith(
                                fontSize: 16,
                                color: isDisabled ? Colors.grey : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isFirstItem) ...[
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
                                'FREE',
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
                        isFirstItem
                            ? 'Available for all users'
                            : isDisabled
                                ? 'Upgrade to access this test'
                                : 'Previous year test paper',
                        style: AppTheme.captionStyle.copyWith(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTrailingWidget(isStarterPlan, isFirstItem, isDisabled,
                    isAdmin, testName, docId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingWidget(bool isStarterPlan, bool isFirstItem,
      bool isDisabled, bool isAdmin, String testName, String docId) {
    if (isAdmin) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {
              if (isDisabled) return;
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
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit,
                color: Colors.blue,
                size: 18,
              ),
            ),
          ),
        ],
      );
    } else if (isStarterPlan && !isFirstItem && isDisabled) {
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
    } else if (!isDisabled) {
      return const Icon(
        Icons.arrow_forward_ios,
        color: Colors.indigoAccent,
        size: 20,
      );
    }
    return const SizedBox.shrink();
  }
}
