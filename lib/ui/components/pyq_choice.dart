import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/features/courses/pyq/pyq_test_year.dart';
import 'package:cet_verse/ui/components/AddPyq.dart';
import 'package:flutter/material.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class PYQChoice extends StatefulWidget {
  const PYQChoice({super.key});

  @override
  _PYQChoiceState createState() => _PYQChoiceState();
}

class _PYQChoiceState extends State<PYQChoice> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate initial loading
    _loadContent();
  }

  Future<void> _loadContent() async {
    // Simulate loading time
    await Future.delayed(const Duration(milliseconds: 20));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate refresh loading
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
          'Group Wise Practice',
          style: AppTheme.subheadingStyle.copyWith(
            fontSize: 24,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        backgroundColor: Colors.white,
        color: Colors.indigoAccent,
        strokeWidth: 3.0,
        displacement: 40.0,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverToBoxAdapter(
                child: _isLoading
                    ? _buildShimmerContent()
                    : _buildContent(authProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildShimmerCard(),
        const SizedBox(height: 24),
        _buildShimmerCard(),
        const SizedBox(height: 32),
        _buildShimmerAdminButton(),
      ],
    );
  }

  Widget _buildShimmerCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shimmer for icon
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Shimmer for title
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                width: 80,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Shimmer for description - multiple lines
            Column(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    width: 250,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerAdminButton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildContent(AuthProvider authProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildOptionCard(
          context,
          icon: Icons.science_outlined,
          title: 'PCM',
          description:
              'Attempt full-length PYQ Tests in Physics, Chemistry, and Mathematics. Track your progress and scores!',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PYQTestYear(
                  pyqType: 'PCM',
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        _buildOptionCard(
          context,
          icon: Icons.biotech_outlined,
          title: 'PCB',
          description:
              'Attempt full-length PYQ Tests in Physics, Chemistry, and Biology. Track your progress and scores!',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PYQTestYear(
                  pyqType: 'PCB',
                ),
              ),
            );
          },
        ),
        if (authProvider.getUserType?.toLowerCase() == 'admin') ...[
          const SizedBox(height: 32),
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
              backgroundColor: Colors.indigoAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: const Text(
              'Add New Test',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
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
        onTap: onTap,
        splashColor: Colors.indigoAccent.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.indigoAccent, size: 56),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTheme.subheadingStyle.copyWith(
                  fontSize: 22,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: AppTheme.captionStyle.copyWith(
                  fontSize: 14,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
