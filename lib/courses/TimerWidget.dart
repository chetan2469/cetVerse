import 'package:cet_verse/courses/TimerController.dart';
import 'package:flutter/material.dart';

class TimerWidget extends StatefulWidget {
  final TimerController controller;

  const TimerWidget({super.key, required this.controller});

  @override
  _TimerWidgetState createState() => _TimerWidgetState();
}

class _TimerWidgetState extends State<TimerWidget> {
  late int _timeRemaining;

  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.controller.timeRemaining;
    widget.controller.addListener(_onTimeChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTimeChanged);
    super.dispose();
  }

  void _onTimeChanged(int newTime) {
    setState(() {
      _timeRemaining = newTime;
    });
  }

  String _formatTime(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: _timeRemaining < 60 ? Colors.red[100] : Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _timeRemaining < 60 ? Colors.red : Colors.blue,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer,
            size: 18,
            color: _timeRemaining < 60 ? Colors.red : Colors.blue,
          ),
          const SizedBox(width: 4),
          Text(
            _formatTime(_timeRemaining),
            style: TextStyle(
              color: _timeRemaining < 60 ? Colors.red : Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
