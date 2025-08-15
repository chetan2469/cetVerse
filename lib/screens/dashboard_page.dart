import 'package:cet_verse/features/courses/popular_courses_page.dart';
import 'package:cet_verse/screens/performance_page.dart';
import 'package:cet_verse/ui/components/header_page.dart';
import 'package:cet_verse/ui/components/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/ui/theme/constants.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    // Function to handle refresh logic
    Future<void> handleRefresh() async {
      // Simulate a network call or data reload with a delay
      await Future.delayed(const Duration(seconds: 2));
      // Optionally, trigger specific reloads here, e.g.:
      // - authProvider.fetchUserData(user?.phoneNumber ?? '');
      // - Reload images or data in PopularCoursesPage via a provider
    }

    return SafeArea(
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: AppTheme.scaffoldBackground,
        drawer: const MyDrawer(),
        body: RefreshIndicator(
          onRefresh: handleRefresh, // Called when user pulls down to refresh
          color: AppTheme.primaryColor ?? Colors.blue, // Spinner color
          backgroundColor: Colors.white, // Background of the spinner
          displacement: 40, // Distance from top where the indicator appears
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ), // Ensure scrollability even with short content
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ), // Ensure content takes up at least full screen height
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeaderPage(
                    user: user,
                    onDrawerOpen: () => scaffoldKey.currentState?.openDrawer(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8),
                    child: Column(
                      children: [
                        // const SizedBox(height: 24),
                        // PromoBannerPage(),
                        PerformancePage(),
                        const SizedBox(height: 24),
                        const PopularCoursesPage(),
                        const SizedBox(height: 24),
                        // Uncomment/add more widgets to increase content height if needed
                        // const SearchBarPage(),
                        // const SizedBox(height: 24),
                        // const SubjectsPage(),
                        // const SizedBox(height: 24),
                        // const YourCoursesPage(),
                      ],
                    ),
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
