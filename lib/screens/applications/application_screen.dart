import 'package:flutter/material.dart';

class ApplicationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Applications dashboard coming soon. Landlords will manage inquiries here.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
