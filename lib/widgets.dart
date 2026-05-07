import 'package:flutter/material.dart';

class LineInput extends StatelessWidget {
  const LineInput({
    super.key,
    required this.hint,
    required this.icon,
    required this.accent,
    this.fillColor,
    this.suffixIcon,
    this.obscureText = false,
    this.controller,
    this.focusNode,
    this.onChanged,
  });

  final String hint;
  final IconData icon;
  final Color accent;
  final Color?fillColor;
  final Widget?suffixIcon;
  final bool obscureText;
  final TextEditingController?controller;
  final FocusNode?focusNode;
  final ValueChanged<String>?onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        filled: true,
        fillColor: fillColor ?? Colors.white.withOpacity(0.08),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.75)),
        prefixIcon: Icon(icon, color: accent),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: accent, width: 1.4),
        ),
      ),
    );
  }
}
