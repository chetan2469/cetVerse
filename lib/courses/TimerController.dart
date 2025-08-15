import 'dart:async';
import 'dart:ui';

class TimerController {
  int _timeRemaining = 0;
  Timer? _timer;
  VoidCallback? _onTimeUp;
  final List<Function(int)> _listeners = [];

  void initialize(int totalTime, VoidCallback? onTimeUp) {
    _timeRemaining = totalTime;
    _onTimeUp = onTimeUp;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        _timeRemaining--;
        _notifyListeners();
      } else {
        stop();
        _onTimeUp?.call();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    _listeners.clear();
  }

  void addListener(Function(int) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(int) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      listener(_timeRemaining);
    }
  }

  String formatTime(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  int get timeRemaining => _timeRemaining;
}
