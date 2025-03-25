import 'package:flutter/material.dart';

class ShowTitle extends StatelessWidget {
  // Get 2 parameters from the parent widget
  final String title;
  final TextStyle? textStyle;

  const ShowTitle({
    super.key,
    required this.title,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Text(title, style: textStyle);
  }
}