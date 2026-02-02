import 'package:flutter/material.dart';

/// 큰 이모지 아이콘
class EmojiIcon extends StatelessWidget {
  final String emoji;
  final double size;

  const EmojiIcon({
    super.key,
    required this.emoji,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      emoji,
      style: TextStyle(fontSize: size),
      textAlign: TextAlign.center,
    );
  }
}
