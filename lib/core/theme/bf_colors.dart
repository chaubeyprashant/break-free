import 'package:flutter/material.dart';

/// Break Free color tokens — restrained premium palette.
/// One primary accent; success / warning / danger only for semantic states.
abstract final class BfColors {
  // Surfaces (dark-first product feel; light theme mirrors structure)
  static const Color ink = Color(0xFF0B0D10);
  static const Color inkElevated = Color(0xFF14181F);
  static const Color inkSoft = Color(0xFF1C222B);
  static const Color inkMuted = Color(0xFF2A323E);

  static const Color paper = Color(0xFFF5F4F1);
  static const Color paperElevated = Color(0xFFFFFFFF);
  static const Color paperSoft = Color(0xFFECEAE5);

  // Accent — single brand teal (calm, mature)
  static const Color accent = Color(0xFF3D9B8F);
  static const Color accentMuted = Color(0xFF2A6F67);
  static const Color accentSoft = Color(0x1A3D9B8F);

  // Text
  static const Color textPrimaryDark = Color(0xFFF2F1EE);
  static const Color textSecondaryDark = Color(0xFF9AA3B0);
  static const Color textTertiaryDark = Color(0xFF6B7380);

  static const Color textPrimaryLight = Color(0xFF14181F);
  static const Color textSecondaryLight = Color(0xFF5C6570);
  static const Color textTertiaryLight = Color(0xFF8A919C);

  // Borders
  static const Color borderDark = Color(0x1AFFFFFF);
  static const Color borderLight = Color(0x14000000);

  // Semantic
  static const Color success = Color(0xFF4A9B7A);
  static const Color warning = Color(0xFFC4A35A);
  static const Color danger = Color(0xFFC45C5C);

  static const Color focusRing = Color(0x403D9B8F);
}
