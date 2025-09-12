import 'package:cet_verse/courses/TimerController.dart';
import 'package:cet_verse/courses/TimerWidget.dart';
import 'package:cet_verse/features/courses/pyq/TestSideBar.dart';
import 'package:cet_verse/features/courses/pyq/tests/new_test_view/logic.dart';
import 'package:cet_verse/features/courses/pyq/tests/new_test_view/widets.dart';
import 'package:cet_verse/ui/components/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'test_provider.dart';

/// A wrapper to provide the TestProvider to the Test screen.
class TestWrapper extends StatelessWidget {
  final String year;
  final String pyqType;
  final String docId;

  const TestWrapper({
    super.key,
    required this.year,
    required this.pyqType,
    required this.docId,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TestProvider(year: year, pyqType: pyqType, docId: docId),
      child: const TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final TimerController _timerController = TimerController();
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // ✅ fixed

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showStartConfirmation(context, _timerController);
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TestProvider>(
      builder: (context, provider, child) {
        final isPcm = provider.pyqType.toLowerCase() == 'pcm';

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (!didPop) {
              final bool? shouldPop = await showBackConfirmation2(context);
              if (shouldPop == true && context.mounted) {
                Navigator.pop(context);
              }
            }
          },
          child: Scaffold(
            key: _scaffoldKey,
            drawer: const MyDrawer(),
            endDrawer: TestSideBar(
              pyqType: provider.pyqType,
              userAnswers: provider.userAnswers,
              reviewedQuestions: provider.reviewedQuestions,
              mcqs: provider.mcqs,
              hasSubmitted: provider.hasSubmitted,
              onJumpToQuestion: provider.jumpToQuestion,
            ),
            backgroundColor: Colors.grey.shade50,
            appBar: AppBar(
              leading: Builder(
                builder: (context) => Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.blueGrey),
                    onPressed: () => showBackConfirmation2(context),
                  ),
                ),
              ),
              title: const Text(
                'PYQ Test',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: Colors.grey.shade300,
                ),
              ),
              actions: [
                if (!provider.isLoading &&
                    provider.mcqs.isNotEmpty &&
                    provider.hasConfirmedStart)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: TimerWidget(controller: _timerController),
                  ),
              ],
            ),
            body: !provider.hasConfirmedStart
                ? buildWaitingScreen()
                : provider.isLoading
                    ? buildLoadingScreen()
                    : provider.errorMessage != null
                        ? buildErrorScreen(provider)
                        : buildMainContent(_scaffoldKey, provider, isPcm),
            bottomNavigationBar: (provider.hasConfirmedStart &&
                    !provider.isLoading)
                ? buildBottomNavigationBar(context, provider, _timerController)
                : null,
            // bottomNavigationBar: _buildBottomNavigationBar(provider),
          ),
        );
      },
    );
  }
}
