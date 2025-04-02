import 'package:cet_verse/constants.dart';
import 'package:flutter/material.dart';

class PromoBannerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none, // Allows image overflow
      children: [
        // Background Container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 32, 33, 34),
                AppTheme.accentColor
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "7 Days Free Trial",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Access exclusive Material",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text("Upgrade",
                          style: AppTheme.captionStyle.copyWith(
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Popping Image
        Positioned(
          right: -10, // Move image slightly outside
          top: -46, // Move image above the container
          child: Image.asset(
            "assets/promogirl2.png",
            width: MediaQuery.sizeOf(context).width * .45,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}
