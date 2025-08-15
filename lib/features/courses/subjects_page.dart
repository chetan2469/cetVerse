import 'package:flutter/material.dart';
import 'package:cet_verse/ui/theme/constants.dart';

class SubjectsPage extends StatelessWidget {
  const SubjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Subjects"),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildSubjectChip("All", isSelected: true),
              const SizedBox(width: 8),
              _buildSubjectChip("Physics", color: AppTheme.businessColor),
              const SizedBox(width: 8),
              _buildSubjectChip("Chemistry", color: AppTheme.tradingColor),
              const SizedBox(width: 8),
              _buildSubjectChip("Maths", color: AppTheme.designColor),
              const SizedBox(width: 8),
              _buildSubjectChip("Biology"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectChip(String label,
      {bool isSelected = false, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor : (color ?? Colors.grey[200]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: AppTheme.captionStyle.copyWith(
          color: isSelected ? Colors.white : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTheme.subheadingStyle),
        Text(
          "See all",
          style: AppTheme.captionStyle.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
