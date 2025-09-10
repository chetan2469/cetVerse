import 'package:flutter/material.dart';

class OptionWidget extends StatefulWidget {
  final String optionId;
  final String optionLabel;
  final String optionContent;
  final bool isSelected;
  final VoidCallback onTap;
  final bool hasSubmitted;

  const OptionWidget({
    Key? key,
    required this.optionId,
    required this.optionLabel,
    required this.optionContent,
    required this.isSelected,
    required this.onTap,
    required this.hasSubmitted,
  }) : super(key: key);

  @override
  _OptionWidgetState createState() => _OptionWidgetState();
}

class _OptionWidgetState extends State<OptionWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.hasSubmitted ? null : widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:
              widget.isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: widget.isSelected ? Colors.blue : Colors.grey.shade300,
            width: widget.isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isSelected ? Colors.blue : Colors.transparent,
                border: Border.all(
                  color: widget.isSelected ? Colors.blue : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: widget.isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            Expanded(
              child: Text(
                '${widget.optionLabel}: ${widget.optionContent}',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      widget.isSelected ? Colors.blue.shade800 : Colors.black87,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
