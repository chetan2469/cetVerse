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
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
                onPressed: () async {
                  final shouldExit = await showGeneralDialog<bool>(
                        context: context,
                        barrierDismissible: false,
                        barrierLabel: '',
                        barrierColor: Colors.black54,
                        transitionDuration: const Duration(milliseconds: 300),
                        pageBuilder: (ctx, animation, secondaryAnimation) =>
                            Container(),
                        transitionBuilder:
                            (ctx, animation, secondaryAnimation, child) {
                          return ScaleTransition(
                            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                              CurvedAnimation(
                                  parent: animation, curve: Curves.easeOutBack),
                            ),
                            child: FadeTransition(
                              opacity: animation,
                              child: AlertDialog(
                                backgroundColor: Colors.white,
                                elevation: 24,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                contentPadding: const EdgeInsets.all(24),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.orange.shade100,
                                            Colors.red.shade100
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Icon(Icons.warning_amber_rounded,
                                          color: Colors.red.shade600, size: 32),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'Hold on!',
                                      style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Are you sure you want to leave? Your progress might not be saved.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade600,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                              side: BorderSide(
                                                  color: Colors.grey.shade300),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text('Cancel',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500)),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: FilledButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            style: FilledButton.styleFrom(
                                              backgroundColor:
                                                  Colors.red.shade500,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 14),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child: const Text('Leave',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ) ??
                      false;
                  if (shouldExit) Navigator.of(context).pop();
                },
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
