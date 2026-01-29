import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:date_and_doing/api/api_service.dart';

/// Mini-model para lo que necesitas del API externo.
class LugarLite {
  final String id;
  final String username;
  final String fullName;
  final String biography;
  final String url;
  final String profilePic;

  LugarLite({
    required this.id,
    required this.username,
    required this.fullName,
    required this.biography,
    required this.url,
    required this.profilePic,
  });

  String get displayName => fullName.trim().isNotEmpty ? fullName.trim() : "@${username.trim()}";

  factory LugarLite.fromMap(Map<String, dynamic> m) {
    return LugarLite(
      id: (m["id"] ?? "").toString(),
      username: (m["username"] ?? "").toString(),
      fullName: (m["full_name"] ?? "").toString(),
      biography: (m["biography"] ?? "").toString(),
      url: (m["url"] ?? "").toString(),
      profilePic: (m["profile_pic_url_hd"] ?? m["profile_pic_url"] ?? "").toString(),
    );
  }
}

class LugarPickerSheet extends StatefulWidget {
  final ApiService api;
  final String category;
  final String? selectedId;
  final String title;

  const LugarPickerSheet({
    super.key,
    required this.api,
    required this.category,
    required this.title,
    this.selectedId,
  });

  @override
  State<LugarPickerSheet> createState() => _LugarPickerSheetState();
}

class _LugarPickerSheetState extends State<LugarPickerSheet> {
  late Future<List<LugarLite>> _future;
  String _query = "";

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<LugarLite>> _load() async {
    // Tu apiService debe retornar List<Map<String,dynamic>> (items)
    final raw = await widget.api.getLugares(widget.category);
    return raw.map((e) => LugarLite.fromMap(e)).toList();
  }

  void _retry() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                color: Colors.black.withOpacity(0.15),
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Buscar tienda por nombre o usuario…",
                    filled: true,
                    fillColor: cs.surfaceVariant.withOpacity(0.55),
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: cs.outline.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: cs.outline.withOpacity(0.2)),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: FutureBuilder<List<LugarLite>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: cs.primary),
                      );
                    }

                    if (snap.hasError) {
                      return _ErrorState(
                        cs: cs,
                        text: "No se pudieron cargar tiendas.\n${snap.error}",
                        onRetry: _retry,
                      );
                    }

                    final all = snap.data ?? [];
                    final filtered = _query.isEmpty
                        ? all
                        : all.where((x) {
                            final name = x.displayName.toLowerCase();
                            final user = x.username.toLowerCase();
                            return name.contains(_query) || user.contains(_query);
                          }).toList();

                    if (filtered.isEmpty) {
                      return _EmptyState(cs: cs, text: "No hay resultados.");
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final item = filtered[i];
                        final selected = item.id == widget.selectedId;

                        return _LugarCard(
                          cs: cs,
                          selected: selected,
                          title: item.displayName,
                          subtitle: item.biography.trim().isEmpty
                              ? "Sin biografía"
                              : item.biography.trim(),
                          imageUrl: item.profilePic,
                          onTap: () => Navigator.pop(context, item),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LugarCard extends StatelessWidget {
  final ColorScheme cs;
  final bool selected;
  final String title;
  final String subtitle;
  final String imageUrl;
  final VoidCallback onTap;

  const _LugarCard({
    required this.cs,
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = selected ? cs.primary : cs.outline.withOpacity(0.25);
    final bg = selected ? cs.primary.withOpacity(0.08) : cs.surface;
    final chipBg = selected ? cs.primary : cs.surfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: selected ? 1.6 : 1.2),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              offset: const Offset(0, 6),
              color: Colors.black.withOpacity(0.05),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _Avatar(url: imageUrl, cs: cs),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: chipBg.withOpacity(selected ? 0.18 : 0.55),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: cs.outline.withOpacity(0.18)),
                        ),
                        child: Text(
                          selected ? "Seleccionado" : "Elegir",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: selected ? cs.primary : cs.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.72),
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      fontSize: 12.2,
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

class _Avatar extends StatelessWidget {
  final String url;
  final ColorScheme cs;

  const _Avatar({required this.url, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.surfaceVariant.withOpacity(0.7),
        border: Border.all(color: cs.outline.withOpacity(0.2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? Icon(Icons.store, color: cs.onSurface.withOpacity(0.45))
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.store, color: cs.onSurface.withOpacity(0.45)),
            ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final ColorScheme cs;
  final String text;
  final VoidCallback onRetry;

  const _ErrorState({required this.cs, required this.text, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.withOpacity(0.85)),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.85),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text("Reintentar", style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme cs;
  final String text;

  const _EmptyState({required this.cs, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          color: cs.onSurface.withOpacity(0.7),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}