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

    Future<void> handleRefresh() async {
      await Future.delayed(const Duration(seconds: 2));
    }

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: AppTheme.scaffoldBackground,
      drawer: const MyDrawer(),
      body: RefreshIndicator(
        onRefresh: handleRefresh,
        color: AppTheme.primaryColor ?? Colors.blue,
        backgroundColor: Colors.white,
        displacement: 40,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => const [
            SliverAppBar(
              pinned: false,
              floating: false,
              snap: false,
              elevation: 0,
              backgroundColor: Colors.transparent,
              automaticallyImplyLeading: false,
              toolbarHeight:
                  0, // using SliverAppBar as requested; no visual change
            ),
          ],
          body: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeaderPage(
                    user: user,
                    onDrawerOpen: () => scaffoldKey.currentState?.openDrawer(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 8),
                    child: Column(
                      children: [
                        PerformancePage(),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: const PopularCoursesPage(),
                        ),
                        const SizedBox(height: 24),
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
