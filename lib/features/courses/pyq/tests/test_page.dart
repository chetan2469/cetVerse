import 'dart:async';
import 'package:cet_verse/features/courses/pyq/TestSideBar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cet_verse/core/auth/AuthProvider.dart';
import 'package:cet_verse/courses/TimerController.dart';
import 'package:cet_verse/courses/TimerWidget.dart';
import 'package:cet_verse/features/courses/tests/test_result_page.dart';
import 'package:cet_verse/ui/components/my_drawer.dart';

import 'PyqQuestionCard.dart';
import 'test_dialogs.dart';
import 'test_ui_components.dart';
import 'test_logic.dart';

class Test extends StatefulWidget {
  final String year;
  final String pyqType;
  final String docId;

  const Test({
    super.key,
    required this.year,
    required this.pyqType,
    required this.docId,
  });

  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<Test>
    with TickerProviderStateMixin, TestDialogs, TestUIComponents, TestLogic {
  // State variables
  List<int> userAnswers = [];
  Set<int> reviewedQuestions = {};
  int _currentIndex = 0;
  bool _hasSubmitted = false;
  bool _isTransitioning = false;
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _mcqs = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Map<int, Widget> _questionCache = {};
  final TimerController _timerController = TimerController();
  bool _hasConfirmedStart = false;

  // NEW: Selected tab tracking
  String _selectedTab = 'All';

  late AnimationController _loadingController;
  late Animation<double> _loadingAnimation;

  @override
  void initState() {
    super.initState();

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _loadingController.repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showStartConfirmation();
    });
  }

  @override
  void dispose() {
    _loadingController.dispose();
    _scrollController.dispose();
    _questionCache.clear();
    _timerController.dispose();
    super.dispose();
  }

  // Getters for mixins
  @override
  String get year => widget.year;

  @override
  String get pyqType => widget.pyqType;

  @override
  String get docId => widget.docId;

  @override
  List<Map<String, dynamic>> get mcqs => _mcqs;

  @override
  int get currentIndex => _currentIndex;

  @override
  bool get hasSubmitted => _hasSubmitted;

  @override
  bool get isTransitioning => _isTransitioning;

  @override
  TimerController get timerController => _timerController;

  @override
  ScrollController get scrollController => _scrollController;

  @override
  Map<int, Widget> get questionCache => _questionCache;

  @override
  String? get errorMessage => _errorMessage;

  // NEW: Selected tab getter
  @override
  String get selectedTab => _selectedTab;

  // Setters for mixins
  @override
  set mcqs(List<Map<String, dynamic>> value) => _mcqs = value;

  @override
  set isLoading(bool value) => _isLoading = value;

  @override
  set errorMessage(String? value) => _errorMessage = value;

  @override
  set currentIndex(int value) => _currentIndex = value;

  @override
  set hasSubmitted(bool value) => _hasSubmitted = value;

  @override
  set isTransitioning(bool value) => _isTransitioning = value;

  @override
  set hasConfirmedStart(bool value) => _hasConfirmedStart = value;

  // NEW: Selected tab setter
  @override
  set selectedTab(String value) => _selectedTab = value;

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final isPcm = widget.pyqType.toLowerCase() == 'pcm';
    final attemptedCount = userAnswers.where((answer) => answer != -1).length;
    final totalQuestions =
        _mcqs.isNotEmpty ? _mcqs.length : (isPcm ? 150 : 200);

    return Scaffold(
      key: scaffoldKey,
      drawer: const MyDrawer(),
      endDrawer: TestSideBar(
        pyqType: widget.pyqType,
        userAnswers: userAnswers,
        reviewedQuestions: reviewedQuestions,
        mcqs: _mcqs,
        hasSubmitted: _hasSubmitted,
        onJumpToQuestion: jumpToQuestion,
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
              onPressed: () => showBackConfirmation(context),
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
          if (!_isLoading && _mcqs.isNotEmpty && _hasConfirmedStart)
            Padding(
              padding: const EdgeInsets.all(8),
              child: TimerWidget(controller: _timerController),
            ),
        ],
      ),
      body: !_hasConfirmedStart
          ? buildWaitingScreen()
          : _isLoading
              ? buildLoadingScreen()
              : _errorMessage != null
                  ? buildErrorScreen()
                  : buildMainContent(
                      scaffoldKey, isPcm, attemptedCount, totalQuestions),
      bottomNavigationBar: buildBottomNavigationBar(),
    );
  }
}
