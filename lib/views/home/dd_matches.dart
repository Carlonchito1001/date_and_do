import 'package:flutter/material.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';
import 'package:date_and_doing/views/home/matches/match_profile_page.dart';
import 'package:date_and_doing/widgets/user_photo_view.dart';

class DdMatchesPage extends StatefulWidget {
  const DdMatchesPage({super.key});

  @override
  State<DdMatchesPage> createState() => _DdMatchesPageState();
}

class _DdMatchesPageState extends State<DdMatchesPage> {
  final ApiService _api = ApiService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _matches = [];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final token = await SharedPreferencesService().getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception("No hay token de acceso");
      }

      final data = await _api.allMatches(accessToken: token);

      if (!mounted) return;
      setState(() {
        _matches = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Map<String, dynamic>? _otherUserFrom(Map<String, dynamic> m) {
    final ou = m["other_user"];
    if (ou is Map<String, dynamic>) return ou;
    return null;
  }

  int _matchIdFrom(Map<String, dynamic> m) {
    final raw = m["ddm_int_id"] ?? m["id"] ?? m["match_id"];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? "") ?? 0;
  }

  String _nameFrom(Map<String, dynamic> m) {
    final ou = _otherUserFrom(m);
    final v =
        ou?['use_txt_fullname'] ??
        ou?['fullname'] ??
        m['nombre'] ??
        m['use_txt_fullname'] ??
        m['full_name'] ??
        m['fullname'];

    return (v ?? 'Usuario').toString();
  }

  int _ageFrom(Map<String, dynamic> m) {
    final ou = _otherUserFrom(m);
    final v = ou?['use_txt_age'] ?? ou?['age'] ?? m['edad'] ?? m['age'];

    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  String? _photoBase64From(Map<String, dynamic> m) {
    final ou = _otherUserFrom(m);
    final v = ou?['photo_preview_base64'];
    final s = (v ?? '').toString();
    return s.isNotEmpty ? s : null;
  }

  String _photoFallbackFrom(Map<String, dynamic> m) {
    final ou = _otherUserFrom(m);
    final v =
        ou?['photo_fallback_url'] ??
        ou?['photo'] ??
        m['foto'] ??
        m['photo'] ??
        m['avatar'] ??
        m['use_txt_avatar'];

    return (v ?? '').toString();
  }

  String _statusKeyFrom(Map<String, dynamic> m) {
    final status = (m["ddm_txt_status"] ?? m["status"] ?? "ACTIVO")
        .toString()
        .toUpperCase();
    return status;
  }

  bool _isNewMatch(Map<String, dynamic> m) {
    final createdAt = (m["ddm_timestamp_datecreate"] ?? m["created_at"])
        ?.toString();
    if (createdAt == null || createdAt.isEmpty) return false;

    final dt = DateTime.tryParse(createdAt);
    if (dt == null) return false;

    final diff = DateTime.now().difference(dt).inHours;
    return diff <= 24;
  }

  String _newMatchLabel(Map<String, dynamic> m) {
    return _isNewMatch(m) ? "Nuevo match" : "Toca para ver perfil";
  }

  Future<void> _open(Map<String, dynamic> item) async {
    final matchId = _matchIdFrom(item);
    if (matchId == 0) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MatchProfilePage(matchId: matchId)),
    );

    if (!mounted) return;
    await _loadMatches();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Matches")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 56),
                const SizedBox(height: 12),
                Text(
                  "No se pudieron cargar tus matches",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadMatches,
                  child: const Text("Reintentar"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Matches")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  size: 64,
                  color: cs.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  "Aún no tienes matches",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Cuando hagas match con alguien aparecerá aquí.",
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Matches")),
      body: RefreshIndicator(
        onRefresh: _loadMatches,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                "Toca un match para ver su perfil ✨",
                style: textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: _matches.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, index) {
                  final item = _matches[index];
                  final name = _nameFrom(item);
                  final age = _ageFrom(item);
                  final photoBase64 = _photoBase64From(item);
                  final photoFallback = _photoFallbackFrom(item);
                  final status = _statusKeyFrom(item);
                  final label = _newMatchLabel(item);

                  return _MatchCard(
                    name: name,
                    age: age,
                    photoBase64: photoBase64,
                    photoFallbackUrl: photoFallback,
                    status: status,
                    label: label,
                    onTap: () => _open(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final String name;
  final int age;
  final String? photoBase64;
  final String photoFallbackUrl;
  final String status;
  final String label;
  final VoidCallback onTap;

  const _MatchCard({
    required this.name,
    required this.age,
    required this.photoBase64,
    required this.photoFallbackUrl,
    required this.status,
    required this.label,
    required this.onTap,
  });

  String _initials(String value) {
    final parts = value.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return "M";
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: UserPhotoView(
                        base64String: photoBase64,
                        fallbackUrl: photoFallbackUrl,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: Colors.grey.shade300,
                          alignment: Alignment.center,
                          child: Text(
                            _initials(name),
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: status == "ACTIVO"
                            ? Colors.green.withOpacity(0.9)
                            : Colors.grey.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    age > 0 ? "$name, $age" : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Ver perfil",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.65),
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}