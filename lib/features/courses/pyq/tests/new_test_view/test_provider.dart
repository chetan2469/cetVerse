import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class TestProvider with ChangeNotifier {
  final String year;
  final String pyqType;
  final String docId;

  TestProvider(
      {required this.year, required this.pyqType, required this.docId});

  // Private state variables
  List<Map<String, dynamic>> _mcqs = [];
  List<Map<String, dynamic>> _filteredMcqs = [];
  List<int> _userAnswers = [];
  final Set<int> _reviewedQuestions = {};
  int _currentIndex = 0;
  bool _hasSubmitted = false;
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedSubject = 'All';
  bool _hasConfirmedStart = false;
  bool _isTransitioning = false; // NEW: prevent double navigation

  // Getters
  List<Map<String, dynamic>> get mcqs => _mcqs;
  List<Map<String, dynamic>> get filteredMcqs => _filteredMcqs;
  List<int> get userAnswers => _userAnswers;
  Set<int> get reviewedQuestions => _reviewedQuestions;
  int get currentIndex => _currentIndex;
  bool get hasSubmitted => _hasSubmitted;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedSubject => _selectedSubject;
  bool get hasConfirmedStart => _hasConfirmedStart;
  bool get isTransitioning => _isTransitioning;

  /// CONFIRM START & FETCH MCQS
  void confirmStart() {
    _hasConfirmedStart = true;
    notifyListeners();
    fetchMcqs();
  }

  Future<void> fetchMcqs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('pyq')
          .doc(docId)
          .collection('test')
          .get();

      _mcqs = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'docId': doc.id,
          'subject': data['subject'] ?? 'Unknown',
        };
      }).toList();

      _mcqs.sort(
          (a, b) => int.parse(a['docId']).compareTo(int.parse(b['docId'])));

      if (_mcqs.isEmpty) {
        _errorMessage = 'No MCQs found for $docId';
      } else {
        _userAnswers = List<int>.filled(_mcqs.length, -1, growable: false);
        _filteredMcqs = List.from(_mcqs);
      }
    } catch (e) {
      _errorMessage = 'Error loading MCQs: $e';
      debugPrint('Error fetching MCQs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// FILTER QUESTIONS
  void filterQuestions(String subject) {
    _selectedSubject = subject;
    if (subject == 'All') {
      _filteredMcqs = List.from(_mcqs);
    } else {
      _filteredMcqs = _mcqs.where((mcq) => mcq['subject'] == subject).toList();
    }
    _currentIndex = _filteredMcqs.isNotEmpty ? 0 : -1;
    notifyListeners();
  }

  /// JUMP TO SUBJECT (Physics, Chemistry, Maths, Biology)
  void jumpToSubject(String subject) {
    if (_isTransitioning) return;

    _isTransitioning = true;
    _selectedSubject = subject;

    int targetIndex = 0;
    switch (subject) {
      case 'Physics':
        targetIndex = 0;
        break;
      case 'Chemistry':
        targetIndex = 50;
        break;
      case 'Maths':
      case 'Biology':
        targetIndex = 100;
        break;
      default:
        targetIndex = 0;
    }

    if (targetIndex >= _mcqs.length) {
      targetIndex = _mcqs.length - 1;
    }

    _currentIndex = targetIndex;
    notifyListeners();
    _isTransitioning = false;
  }

  /// NAVIGATION HELPERS
  bool get canGoPrevious {
    if (_selectedSubject == 'Chemistry') {
      return _currentIndex > 50;
    } else if (_selectedSubject == 'Maths' || _selectedSubject == 'Biology') {
      return _currentIndex > 100;
    } else {
      return _currentIndex > 0;
    }
  }

  bool get canGoNext =>
      _currentIndex < _filteredMcqs.length - 1 && !_isTransitioning;

  void nextQuestion() {
    if (canGoNext) {
      _currentIndex++;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (canGoPrevious) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void jumpToQuestion(int originalIndex) {
    if (originalIndex < 0 || originalIndex >= _mcqs.length || _isTransitioning)
      return;

    final targetMcq = _mcqs[originalIndex];
    int filteredIndex = _filteredMcqs.indexOf(targetMcq);

    if (filteredIndex != -1) {
      _currentIndex = filteredIndex;
    } else {
      final subject = targetMcq['subject'] as String? ?? 'All';
      filterQuestions(subject);
      filteredIndex = _filteredMcqs.indexOf(targetMcq);
      if (filteredIndex != -1) _currentIndex = filteredIndex;
    }
    notifyListeners();
  }

  /// ANSWER SELECTION
  void selectAnswer(String id) {
    if (_hasSubmitted) return;

    final optionIndex = int.parse(id.split('_')[1]) - 1;
    if (_currentIndex < 0 || _currentIndex >= _filteredMcqs.length) return;

    final originalIndex = _mcqs.indexOf(_filteredMcqs[_currentIndex]);
    if (originalIndex != -1) {
      if (_userAnswers[originalIndex] == optionIndex) {
        _userAnswers[originalIndex] = -1;
      } else {
        _userAnswers[originalIndex] = optionIndex;
      }
      notifyListeners();
    }
  }

  void toggleReview() {
    if (_hasSubmitted) return;
    if (_currentIndex < 0 || _currentIndex >= _filteredMcqs.length) return;

    final originalIndex = _mcqs.indexOf(_filteredMcqs[_currentIndex]);
    if (originalIndex != -1) {
      if (_reviewedQuestions.contains(originalIndex)) {
        _reviewedQuestions.remove(originalIndex);
      } else {
        _reviewedQuestions.add(originalIndex);
      }
      notifyListeners();
    }
  }

  void submitTest() {
    _hasSubmitted = true;
    notifyListeners();
  }

  int answerToIndex(String answer) {
    switch (answer.toUpperCase()) {
      case 'A':
        return 0;
      case 'B':
        return 1;
      case 'C':
        return 2;
      case 'D':
        return 3;
      default:
        return -1;
    }
  }
}
