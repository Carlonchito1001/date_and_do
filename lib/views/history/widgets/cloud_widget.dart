import 'package:flutter/material.dart';

class CloudWidget extends StatelessWidget {
  final bool small;

  const CloudWidget({super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    final baseWidth = small ? 70.0 : 110.0;
    final baseHeight = small ? 30.0 : 40.0;

    return Opacity(
      opacity: 0.9,
      child: Container(
        width: baseWidth,
        height: baseHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.6),
              blurRadius: 12,
              offset: const Offset(0, 0),
            ),
          ],
        ),
      ),
    );
  }
}
