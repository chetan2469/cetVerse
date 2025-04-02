import 'package:cet_verse/models/UserModel.dart';
import 'package:flutter/material.dart';
import 'package:cet_verse/constants.dart';

class HeaderPage extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onDrawerOpen;

  const HeaderPage({super.key, required this.user, required this.onDrawerOpen});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconButton(
        onPressed: onDrawerOpen,
        icon: const Icon(Icons.menu),
      ),
      title: Text(
        "Hello, ${user?.name ?? 'User'}!",
        style: AppTheme.headingStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        "Lets Practice",
        style: AppTheme.captionStyle,
      ),
      trailing: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.primaryColor, width: 2),
        ),
        child: const CircleAvatar(
          radius: 28,
          backgroundImage: AssetImage('assets/logo.png'),
        ),
      ),
    );
  }
}
