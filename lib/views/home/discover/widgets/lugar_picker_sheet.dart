import 'package:flutter/material.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'place_list_item.dart';

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
  late Future<List<PlaceItem>> _future;
  String _query = "";

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<PlaceItem>> _load() async {
    final raw = await widget.api.getLugares(widget.category);
    return raw.map((e) => PlaceItem.fromMap(e)).toList();
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
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Selecciona un lugar para tu cita",
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: cs.surfaceVariant.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Buscar por nombre o usuario...",
                    filled: true,
                    fillColor: cs.surfaceVariant.withOpacity(0.5),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => setState(() => _query = ""),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: cs.primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // List
              Expanded(
                child: FutureBuilder<List<PlaceItem>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: cs.primary),
                            const SizedBox(height: 16),
                            Text(
                              "Cargando lugares...",
                              style: TextStyle(
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snap.hasError) {
                      return _ErrorView(
                        message: "No se pudieron cargar los lugares.\n${snap.error}",
                        onRetry: _retry,
                      );
                    }

                    final all = snap.data ?? [];
                    final filtered = _query.isEmpty
                        ? all
                        : all.where((x) {
                            final name = x.displayName.toLowerCase();
                            final user = x.username.toLowerCase();
                            final bio = x.biography.toLowerCase();
                            return name.contains(_query) || 
                                   user.contains(_query) ||
                                   bio.contains(_query);
                          }).toList();

                    if (filtered.isEmpty) {
                      return _EmptyView(
                        query: _query,
                        onClear: () => setState(() => _query = ""),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final item = filtered[i];
                        return PlaceListItem(
                          place: item,
                          isSelected: item.id == widget.selectedId,
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: cs.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Reintentar"),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String query;
  final VoidCallback onClear;

  const _EmptyView({required this.query, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: cs.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              query.isEmpty
                  ? "No hay lugares disponibles"
                  : "No se encontraron resultados para \"$query\"",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            if (query.isNotEmpty) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text("Limpiar búsqueda"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}