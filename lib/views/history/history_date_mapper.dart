import 'package:date_and_doing/models/dd_date.dart';
import 'package:date_and_doing/views/history/models/world_level.dart';
import 'package:flutter/material.dart';

class HistoryDateMapper {
  static bool shouldAppear(DdDate date) {
    return date.isConfirmed || date.isCompleted;
  }

  static List<DdDate> filterForHistory(List<DdDate> dates) {
    final filtered = dates.where(shouldAppear).toList();
    filtered.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return filtered;
  }

  static List<WorldLevel> toWorldLevels(List<DdDate> dates) {
    final filtered = filterForHistory(dates);

    return List.generate(filtered.length, (index) {
      final d = filtered[index];
      final isDone = d.isCompleted;
      final isCurrent = d.isConfirmed && !d.isCompleted;

      return WorldLevel(
        id: d.id.toString(),
        title: d.title,
        subtitle: _buildSubtitle(d),
        date: _formatDate(d.scheduledAt),
        icon: _pickIcon(d.title),
        status: isDone
            ? WorldLevelStatus.done
            : isCurrent
                ? WorldLevelStatus.current
                : WorldLevelStatus.locked,
        position: _buildPosition(index),
      );
    });
  }

  static String _buildSubtitle(DdDate d) {
    if (d.isCompleted) return "Recuerdo completado";
    if (d.isConfirmed) return "Próxima aventura";
    return "Capítulo de su historia";
  }

  static String _formatDate(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yyyy = dt.year.toString();
    return "$dd/$mm/$yyyy";
  }

  static IconData _pickIcon(String title) {
    final t = title.toLowerCase();

    if (t.contains("cafe") || t.contains("café")) {
      return Icons.coffee_rounded;
    }
    if (t.contains("cine")) return Icons.movie_rounded;
    if (t.contains("playa")) return Icons.beach_access_rounded;
    if (t.contains("parque")) return Icons.park_rounded;
    if (t.contains("museo")) return Icons.museum_rounded;
    if (t.contains("concierto")) return Icons.music_note_rounded;
    if (t.contains("restaurante")) return Icons.restaurant_rounded;
    if (t.contains("tienda")) return Icons.store_rounded;

    return Icons.favorite_rounded;
  }

  static Offset _buildPosition(int index) {
    final xPattern = [0.18, 0.68, 0.28, 0.74, 0.22, 0.62];
    const yBase = 0.18;
    const yStep = 0.17;

    final x = xPattern[index % xPattern.length];
    final y = yBase + (index * yStep);

    return Offset(x, y);
  }
}