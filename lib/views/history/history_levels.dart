import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:date_and_doing/api/api_service.dart';

import 'models/world_level.dart';
import 'widgets/island_level_node.dart';
import 'widgets/sea_waves_painter.dart';
import 'widgets/world_path_painter.dart';
import 'widgets/cloud_widget.dart';

/// ✅ Tema de fondo del History World
class HistoryBgTheme {
  final String name;
  final List<Color> colors;

  const HistoryBgTheme({required this.name, required this.colors});
}

class HistoryLevelsPage extends StatefulWidget {
  final int matchId;
  final String partnerName;

  const HistoryLevelsPage({
    super.key,
    required this.matchId,
    required this.partnerName,
  });

  @override
  State<HistoryLevelsPage> createState() => _HistoryLevelsPageState();
}

class _HistoryLevelsPageState extends State<HistoryLevelsPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  final _api = ApiService();

  // ✅ Key para persistencia
  static const String _prefsThemeIndexKey = "dd_history_bg_theme_index";

  // ✅ Tema seleccionado
  int _themeIndex = 0;

  // ✅ Citas -> WorldLevels
  bool _loadingDates = true;
  String? _datesError;
  List<WorldLevel> _levels = [];

  // ✅ Temas disponibles
  static const List<HistoryBgTheme> _bgThemes = [
    HistoryBgTheme(
      name: "Tropical",
      colors: [Color(0xFF33D6A6), Color(0xFF28C0F4)],
    ),
    HistoryBgTheme(
      name: "Sunset",
      colors: [Color(0xFFB85CFF), Color(0xFFFF7A59)],
    ),
    HistoryBgTheme(
      name: "Night Sea",
      colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
    ),
    HistoryBgTheme(
      name: "Aurora",
      colors: [Color(0xFF22C55E), Color(0xFF06B6D4)],
    ),
  ];

  @override
  void initState() {
    super.initState();

    _loadThemeIndex();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _loadDatesToWorld(); // ✅ carga real desde API
  }

  Future<void> _loadThemeIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final idx = prefs.getInt(_prefsThemeIndexKey) ?? 0;
      final safeIdx = (idx >= 0 && idx < _bgThemes.length) ? idx : 0;

      if (!mounted) return;
      setState(() => _themeIndex = safeIdx);
    } catch (_) {}
  }

  Future<void> _saveThemeIndex(int idx) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsThemeIndexKey, idx);
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ===== ANIMACIONES =====

  double _bounce(double phase) {
    final t = _controller.value * 2 * pi + phase;
    const amplitude = 6.0;
    return sin(t) * amplitude;
  }

  // ===== CARGA CITA API => WORLD LEVELS =====
  // ✅ SIN FILTRO DE STATUS (como antes)

  Future<void> _loadDatesToWorld() async {
    setState(() {
      _loadingDates = true;
      _datesError = null;
    });

    try {
      final all = await _api.allDates();

      // ✅ todas las citas del match actual (sin filtrar por status)
      final mine = all.where((d) => d["ddm_int_id"] == widget.matchId).toList();

      // orden por fecha
      mine.sort((a, b) {
        final da =
            DateTime.tryParse(a["ddd_timestamp_date"]?.toString() ?? "") ??
            DateTime(1900);
        final db =
            DateTime.tryParse(b["ddd_timestamp_date"]?.toString() ?? "") ??
            DateTime(1900);
        return da.compareTo(db);
      });

      final levels = mine.isEmpty
          ? _defaultLockedWorld()
          : _mapDatesToWorldLevels(mine);

      if (!mounted) return;
      setState(() {
        _levels = levels;
        _loadingDates = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _datesError = e.toString();
        _loadingDates = false;
        _levels = _defaultLockedWorld();
      });
    }
  }

  List<WorldLevel> _defaultLockedWorld() {
    return const [
      WorldLevel(
        title: "Crea tu primera cita",
        date: "Próximamente",
        icon: Icons.lock_rounded,
        status: WorldLevelStatus.locked,
        position: Offset(0.50, 0.55),
      ),
    ];
  }

  List<WorldLevel> _mapDatesToWorldLevels(List<Map<String, dynamic>> dates) {
    final now = DateTime.now();
    final positions = _generatePositions(dates.length);

    // primera futura => current
    int currentIndex = -1;
    for (int i = 0; i < dates.length; i++) {
      final dt = DateTime.tryParse(
        dates[i]["ddd_timestamp_date"]?.toString() ?? "",
      );
      if (dt != null && dt.isAfter(now)) {
        currentIndex = i;
        break;
      }
    }
    // si no hay futuras, la última es current
    if (currentIndex == -1 && dates.isNotEmpty) currentIndex = dates.length - 1;

    return List.generate(dates.length, (i) {
      final d = dates[i];

      final title = (d["ddd_txt_title"] ?? "Cita").toString();
      final dt = DateTime.tryParse(d["ddd_timestamp_date"]?.toString() ?? "");
      final dateLabel = dt == null ? "Sin fecha" : _fmtDate(dt);

      // ✅ status del mundo por FECHA (no por ddd_txt_status)
      WorldLevelStatus status;
      if (dt == null) {
        status = WorldLevelStatus.locked;
      } else if (dt.isBefore(now)) {
        status = WorldLevelStatus.done;
      } else if (i == currentIndex) {
        status = WorldLevelStatus.current;
      } else {
        status = WorldLevelStatus.locked;
      }

      return WorldLevel(
        title: title,
        date: dateLabel,
        icon: _iconFromTitle(title),
        status: status,
        position: positions[i],
      );
    });
  }

  // posiciones dinámicas (zigzag diagonal)
  List<Offset> _generatePositions(int n) {
    if (n <= 1) return const [Offset(0.50, 0.55)];

    final List<Offset> out = [];
    for (int i = 0; i < n; i++) {
      final t = i / (n - 1); // 0..1
      final x = 0.15 + 0.70 * t;

      final baseY = 0.70 - 0.45 * t;
      final wiggle = (i % 2 == 0) ? 0.06 : -0.06;
      final y = (baseY + wiggle).clamp(0.18, 0.78);

      out.add(Offset(x, y));
    }
    return out;
  }

  String _fmtDate(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, "0");
    final mm = dt.month.toString().padLeft(2, "0");
    final yy = dt.year.toString();
    return "$dd/$mm/$yy";
  }

  IconData _iconFromTitle(String title) {
    final t = title.toLowerCase();
    if (t.contains("café") || t.contains("cafe"))
      return Icons.local_cafe_rounded;
    if (t.contains("cine")) return Icons.movie_rounded;
    if (t.contains("cena")) return Icons.dinner_dining_rounded;
    if (t.contains("viaje")) return Icons.flight_takeoff_rounded;
    if (t.contains("picnic")) return Icons.park_rounded;
    if (t.contains("playa")) return Icons.beach_access_rounded;
    if (t.contains("museo")) return Icons.museum_rounded;
    if (t.contains("concierto")) return Icons.music_note_rounded;
    return Icons.favorite_rounded;
  }

  // ===== UI =====

  void _openThemePicker() {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Tema del mundo",
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(_bgThemes.length, (i) {
                final t = _bgThemes[i];
                final selected = i == _themeIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      setState(() => _themeIndex = i);
                      await _saveThemeIndex(i);
                      if (mounted) Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary.withOpacity(0.8)
                              : Colors.white.withOpacity(0.25),
                          width: selected ? 2 : 1,
                        ),
                        color: theme.colorScheme.surface.withOpacity(0.08),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 58,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                colors: t.colors,
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              t.name,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (selected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: theme.colorScheme.primary,
                            )
                          else
                            const Icon(Icons.circle_outlined),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bg = _bgThemes[_themeIndex];

    // ✅ métricas
    final totalDates = _levels.length;
    final doneCount = _levels
        .where((e) => e.status == WorldLevelStatus.done)
        .length;

    final totalGoal = 6; // meta
    final progress = totalGoal == 0
        ? 0.0
        : (doneCount / totalGoal).clamp(0.0, 1.0);

    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: bg.colors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              // ================= HEADER =================
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      'HISTORY WORLD',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: "Recargar citas",
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
                      onPressed: _loadingDates ? null : _loadDatesToWorld,
                    ),
                    IconButton(
                      tooltip: "Cambiar tema",
                      icon: const Icon(
                        Icons.palette_rounded,
                        color: Colors.white,
                      ),
                      onPressed: _openThemePicker,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              if (_loadingDates) const LinearProgressIndicator(minHeight: 2),

              if (_datesError != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "No se pudo cargar citas: $_datesError",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: _loadDatesToWorld,
                          child: const Text(
                            "Reintentar",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ========== CARD ARRIBA (MATCH) ==========
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFA726), Color(0xFFFF7043)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.pink.shade400,
                        child: Text(
                          (widget.partnerName.isNotEmpty
                              ? widget.partnerName.trim()[0].toUpperCase()
                              : "U"),
                          style: textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$totalDates citas con ${widget.partnerName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: List.generate(
                                5,
                                (i) => const Icon(
                                  Icons.star_rounded,
                                  size: 16,
                                  color: Colors.yellow,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ========== MUNDO DE ISLAS ==========
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          CustomPaint(
                            size: Size.infinite,
                            painter: SeaWavesPainter(),
                          ),
                          CustomPaint(
                            size: Size.infinite,
                            painter: WorldPathPainter(
                              _levels.map((e) => e.position).toList(),
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              final offsetX =
                                  sin(_controller.value * 2 * pi) * 10;
                              return Stack(
                                children: [
                                  Positioned(
                                    left: 40 + offsetX,
                                    top: 40,
                                    child: const CloudWidget(),
                                  ),
                                  Positioned(
                                    right: 20 - offsetX,
                                    top: 80,
                                    child: const CloudWidget(small: true),
                                  ),
                                ],
                              );
                            },
                          ),
                          for (int i = 0; i < _levels.length; i++)
                            _buildAnimatedLevelNode(
                              level: _levels[i],
                              index: i,
                              width: constraints.maxWidth,
                              height: constraints.maxHeight,
                              textTheme: textTheme,
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),

              // ========== BARRA INFERIOR ==========
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.pink.shade500,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'PROGRESO ',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'CITAS: $doneCount/$totalGoal',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: Colors.yellow,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'NIV 1',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.purple.shade300,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '¡Sigue creando momentos increíbles!',
                      style: textTheme.bodySmall?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLevelNode({
    required WorldLevel level,
    required int index,
    required double width,
    required double height,
    required TextTheme textTheme,
  }) {
    final phase = index * (pi / 2);

    final dx = level.position.dx * width;
    final dy = level.position.dy * height;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final bounceY = _bounce(phase);
        return Positioned(left: dx - 40, top: dy + bounceY, child: child!);
      },
      child: IslandLevelNode(level: level, textTheme: textTheme, onTap: () {}),
    );
  }
}
