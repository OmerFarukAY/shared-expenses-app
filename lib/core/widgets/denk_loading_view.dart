import 'package:flutter/material.dart';

class DenkLoadingView extends StatelessWidget {
  final String? message;

  const DenkLoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        'assets/branding/logo_no_bg.png',
        width: 120, // Enough size to look like a placeholder
        fit: BoxFit.contain,
      ),
    );
  }
}
