import 'package:flutter/material.dart';

enum WorldLevelStatus { done, current, locked }

class WorldLevel {
  final String id;
  final String title;
  final String subtitle;
  final String date;
  final IconData icon;
  final WorldLevelStatus status;

  /// posición relativa en el mundo (0..1, 0..1)
  final Offset position;

  const WorldLevel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.icon,
    required this.status,
    required this.position,
  });
}