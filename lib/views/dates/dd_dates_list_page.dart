import 'package:flutter/material.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/models/dd_date.dart';
import 'package:date_and_doing/widgets/date_card.dart';

class DdDatesListPage extends StatefulWidget {
  final int matchId;
  final String partnerName;

  const DdDatesListPage({
    super.key,
    required this.matchId,
    required this.partnerName,
  });

  @override
  State<DdDatesListPage> createState() => _DdDatesListPageState();
}

class _DdDatesListPageState extends State<DdDatesListPage> {
  final _api = ApiService();

  bool _loading = true;
  String? _error;
  List<DdDate> _dates = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _api.getDatesForMatch(widget.matchId);

      // ordena por fecha (opcional)
      list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

      if (!mounted) return;
      setState(() {
        _dates = list;
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

  Future<void> _confirm(DdDate d) async {
    try {
      await _api.confirmDate(d.id);
      await _load();
      _toast("✅ Cita confirmada");
    } catch (e) {
      _toast("❌ Error: $e");
    }
  }

  Future<void> _reject(DdDate d) async {
    try {
      await _api.rejectDate(d.id);
      await _load();
      _toast("✅ Cita rechazada");
    } catch (e) {
      _toast("❌ Error: $e");
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text("Citas con ${widget.partnerName}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              if (_loading)
                const LinearProgressIndicator(minHeight: 2),

              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.errorContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: cs.onErrorContainer),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: cs.onErrorContainer,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        onPressed: _load,
                        child: Text("Reintentar", style: TextStyle(color: cs.onErrorContainer)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

              Expanded(
                child: _dates.isEmpty && !_loading
                    ? const Center(child: Text("Aún no hay citas"))
                    : ListView.separated(
                        itemCount: _dates.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final d = _dates[i];
                          return DateCard(
                            date: d,
                            onConfirm: () => _confirm(d),
                            onReject: () => _reject(d),
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
