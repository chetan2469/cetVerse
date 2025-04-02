import 'package:flutter/material.dart';
import 'package:cet_verse/constants.dart';

class SearchBarPage extends StatelessWidget {
  const SearchBarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search for courses...",
          hintStyle: AppTheme.captionStyle,
          prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}
