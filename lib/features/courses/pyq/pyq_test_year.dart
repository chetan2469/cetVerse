import 'package:cet_verse/features/courses/pyq/PYQTestNameList.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'package:provider/provider.dart';
import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:shimmer/shimmer.dart';

class PYQTestYear extends StatelessWidget {
  final String pyqType;

  const PYQTestYear({super.key, required this.pyqType});

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
          'Past Year Questions ($pyqType)',
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
                    "Select Year",
                    style: AppTheme.subheadingStyle.copyWith(
                      fontSize: 16,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildYearsSection(context, authProvider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearsSection(BuildContext context, AuthProvider authProvider) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('pyq').get(),
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

        // Extract and process years
        List<int> years = snapshot.data!.docs
            .map((doc) {
              final testYear = doc['testYear'] as int?;
              return testYear ?? 0;
            })
            .where((year) => year != 0)
            .toSet()
            .toList();

        years.sort((a, b) => b.compareTo(a));
        int currentYear = years.isNotEmpty ? years.first : 0;

        return Column(
          children: years.map((year) {
            final isCurrentYear = year == currentYear;
            final isStarterPlan = authProvider.getPlanType == 'Starter';
            final isAdmin = authProvider.userType == 'Admin';
            bool isDisabled = !isCurrentYear && isStarterPlan && !isAdmin;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildYearCard(
                context,
                year: year,
                isCurrentYear: isCurrentYear,
                isDisabled: isDisabled,
                isStarterPlan: isStarterPlan,
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
      children: List.generate(4, (index) => _buildShimmerYearCard()),
    );
  }

  Widget _buildShimmerYearCard() {
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
              // Shimmer for calendar icon
              Shimmer.fromColors(
                baseColor: Colors.grey.shade300,
                highlightColor: Colors.grey.shade100,
                child: Container(
                  width: 64,
                  height: 64,
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
                    // Shimmer for year title
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 120,
                        height: 24,
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
                        height: 16,
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
              'Error loading years',
              style: AppTheme.subheadingStyle.copyWith(
                fontSize: 16,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again later',
              style: AppTheme.captionStyle.copyWith(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Trigger rebuild
              },
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
    );
  }

  Widget _buildEmptyCard() {
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
              'No years found for ${pyqType}',
              style: AppTheme.captionStyle.copyWith(
                fontSize: 14,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearCard(
    BuildContext context, {
    required int year,
    required bool isCurrentYear,
    required bool isDisabled,
    required bool isStarterPlan,
    required AuthProvider authProvider,
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
        splashColor: Colors.indigoAccent.withOpacity(0.2),
        child: Opacity(
          opacity: isDisabled ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCurrentYear
                        ? Colors.indigoAccent
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    size: 22,
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
                          Text(
                            'Year $year',
                            style: AppTheme.subheadingStyle.copyWith(
                              fontSize: 14,
                              color: isDisabled ? Colors.grey : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isCurrentYear) ...[
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
                                'LATEST',
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
                        isCurrentYear
                            ? 'Most recent test papers'
                            : isDisabled
                                ? 'Upgrade to access previous years'
                                : 'Previous year test papers',
                        style: AppTheme.captionStyle.copyWith(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTrailingWidget(isStarterPlan, isCurrentYear, isDisabled),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingWidget(
      bool isStarterPlan, bool isCurrentYear, bool isDisabled) {
    if (isStarterPlan && !isCurrentYear && isDisabled) {
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
