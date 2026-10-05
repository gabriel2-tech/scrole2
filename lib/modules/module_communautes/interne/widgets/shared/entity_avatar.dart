import 'package:flutter/material.dart';

class EntityAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  final double size;

  const EntityAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(size * 0.32)),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.32,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
