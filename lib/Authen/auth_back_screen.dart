import 'package:flutter/material.dart';

class BackScreen extends StatelessWidget {
  const BackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 150,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Color.fromRGBO(76, 175, 80, 0.75),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(2, 2),
          ),
        ],
      ),
    );
  }
}
