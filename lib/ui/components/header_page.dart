import 'package:cet_verse/core/models/user_model.dart';
import 'package:cet_verse/ui/theme/constants.dart';
import 'package:flutter/material.dart';

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
        child: Image.asset('assets/logo.png'),
      ),
    );
  }
}
