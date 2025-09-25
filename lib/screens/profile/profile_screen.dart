import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          minHeight: MediaQuery.of(context).size.height -
              MediaQuery.of(context).padding.top -
              kToolbarHeight -
              kBottomNavigationBarHeight,
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Profile settings coming soon.'),
        ),
      ),
    );
  }
}
