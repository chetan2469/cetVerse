import 'package:flutter/material.dart';

class ToppersNotes extends StatefulWidget {
  const ToppersNotes({super.key});

  @override
  State<ToppersNotes> createState() => _ToppersNotesState();
}

class _ToppersNotesState extends State<ToppersNotes> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Toppers Notes"),
      ),
    );
  }
}
