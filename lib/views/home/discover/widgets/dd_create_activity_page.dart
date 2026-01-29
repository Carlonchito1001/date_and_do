import 'package:flutter/material.dart';
import 'package:date_and_doing/api/api_service.dart';

import 'lugar_picker_sheet.dart';

class DdCreateActivityPage extends StatefulWidget {
  final int matchId;
  final String partnerName;

  const DdCreateActivityPage({
    super.key,
    required this.matchId,
    required this.partnerName,
  });

  @override
  State<DdCreateActivityPage> createState() => _DdCreateActivityPageState();
}

class _DdCreateActivityPageState extends State<DdCreateActivityPage> {
  final _api = ApiService();

  bool _isSaving = false;
  String _selectedId = "playa";

  // ✅ Lugar elegido desde la API externa
  LugarLite? _selectedLugar;

  final _dayCtrl = TextEditingController();
  final _monthCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  TimeOfDay? _selectedTime;

  final List<_ActivityItem> _activities = const [
    _ActivityItem(id: "playa", emoji: "🏖️", label: "Día de Playa"),
    _ActivityItem(id: "parque", emoji: "🌳", label: "Salida al Parque"),
    _ActivityItem(id: "cena", emoji: "🍽️", label: "Cena Romántica"),
    _ActivityItem(id: "cafe", emoji: "☕", label: "Café"),
    _ActivityItem(id: "cine", emoji: "🎬", label: "Cine"),
    _ActivityItem(id: "museo", emoji: "🏛️", label: "Museo"),
    _ActivityItem(id: "concierto", emoji: "🎵", label: "Concierto"),
    _ActivityItem(id: "senderismo", emoji: "🥾", label: "Senderismo"),
    _ActivityItem(id: "picnic", emoji: "🧺", label: "Picnic"),
    _ActivityItem(id: "tienda", emoji: "🛍️", label: "Tienda"),
    _ActivityItem(id: "otra", emoji: "✨", label: "Otra..."),
  ];

  @override
  void dispose() {
    _dayCtrl.dispose();
    _monthCtrl.dispose();
    _yearCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  _ActivityItem get _selectedActivity =>
      _activities.firstWhere((a) => a.id == _selectedId);

  bool get _needsPlacePicker => _selectedId == "tienda";

  DateTime? _tryParseDate() {
    final dd = int.tryParse(_dayCtrl.text.trim());
    final mm = int.tryParse(_monthCtrl.text.trim());
    final yyyy = int.tryParse(_yearCtrl.text.trim());
    if (dd == null || mm == null || yyyy == null) return null;
    if (yyyy < 1900 || yyyy > 2100) return null;

    try {
      final dt = DateTime(yyyy, mm, dd);
      if (dt.year != yyyy || dt.month != mm || dt.day != dd) return null;
      return dt;
    } catch (_) {
      return null;
    }
  }

  DateTime? _buildScheduledLocal() {
    final date = _tryParseDate();
    if (date == null) return null;
    final t = _selectedTime ?? const TimeOfDay(hour: 18, minute: 30);
    return DateTime(date.year, date.month, date.day, t.hour, t.minute);
  }

  Future<void> _openCalendar() async {
    final now = DateTime.now();
    final cs = Theme.of(context).colorScheme;

    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: cs.copyWith(primary: cs.primary)),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _dayCtrl.text = picked.day.toString().padLeft(2, "0");
      _monthCtrl.text = picked.month.toString().padLeft(2, "0");
      _yearCtrl.text = picked.year.toString();
      setState(() {});
    }
  }

  Future<void> _openTimePicker() async {
    final cs = Theme.of(context).colorScheme;

    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 18, minute: 30),
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: cs.copyWith(primary: cs.primary)),
          child: child!,
        );
      },
    );

    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _openLugarPicker() async {
    // 👇 aquí le pasas la categoría (tienda)
    final picked = await showModalBottomSheet<LugarLite>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LugarPickerSheet(
        api: _api,
        category: _selectedId, // "tienda"
        selectedId: _selectedLugar?.id,
        title: "Tiendas disponibles",
      ),
    );

    if (picked != null) {
      setState(() => _selectedLugar = picked);

      // autocompleta el campo Lugar/Nota de forma bonita
      final title = picked.displayName;
      final bio = picked.biography.trim();
      final url = picked.url.trim();

      final lines = <String>[];
      lines.add("📍 $title");
      if (bio.isNotEmpty) lines.add("📝 $bio");
      if (url.isNotEmpty) lines.add("🔗 $url");

      _descCtrl.text = lines.join("\n").trim();
    }
  }

  Future<void> _createDateReal() async {
    if (_isSaving) return;

    final scheduled = _buildScheduledLocal();
    if (scheduled == null) {
      _toast("Ingresa una fecha válida y selecciona una hora.");
      return;
    }
    if (!scheduled.isAfter(DateTime.now())) {
      _toast("La cita debe ser en una fecha/hora futura.");
      return;
    }

    if (_needsPlacePicker && _selectedLugar == null) {
      _toast("Elige una tienda para tu cita 🛍️");
      await _openLugarPicker();
      if (_selectedLugar == null) return;
    }

    final baseDesc = _descCtrl.text.trim().isEmpty
        ? "Sin descripción"
        : _descCtrl.text.trim();

    final placeName = _selectedLugar?.displayName ?? "";
    final placeUrl = _selectedLugar?.url ?? "";

    final description = [
      baseDesc,
      if (placeName.isNotEmpty) "\n🏪 Lugar: $placeName",
      if (placeUrl.isNotEmpty) "🔗 $placeUrl",
    ].join("\n").trim();

    final title = (placeName.isNotEmpty)
        ? "${_selectedActivity.label} • $placeName"
        : _selectedActivity.label;

    setState(() => _isSaving = true);

    try {
      final res = await _api.createDate(
        matchId: widget.matchId,
        title: title,
        description: description,
        scheduledLocal: scheduled,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);

      final createdId = (res["id"] ?? res["ddd_int_id"] ?? "OK").toString();

      final created = _DateCreated(
        id: createdId,
        partnerName: widget.partnerName,
        activityLabel: title,
        activityId: _selectedActivity.id,
        date: scheduled,
        createdAt: DateTime.now(),
      );

      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => _SuccessDialog(created: created),
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _toast("❌ Error creando cita: $e");
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _prettyDateTimeOrEmpty(BuildContext context) {
    final scheduled = _buildScheduledLocal();
    if (scheduled == null) return "—";
    final dd = scheduled.day.toString().padLeft(2, "0");
    final mm = scheduled.month.toString().padLeft(2, "0");
    final yyyy = scheduled.year.toString();
    final t = _selectedTime?.format(context) ?? "18:30";
    return "$dd/$mm/$yyyy • $t";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final top = MediaQuery.of(context).padding.top;

    final headerGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        cs.primary,
        cs.secondaryContainer != cs.primary
            ? cs.secondaryContainer
            : cs.secondary,
      ],
    );

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          // Top bar
          Container(
            padding: EdgeInsets.only(top: top),
            decoration: BoxDecoration(gradient: headerGradient),
            child: SizedBox(
              height: 68,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  _TopIconButton(
                    icon: Icons.close,
                    bg: cs.onPrimary.withOpacity(0.18),
                    fg: cs.onPrimary,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Crear Actividad",
                          style: textTheme.titleSmall?.copyWith(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Planea una cita con ${widget.partnerName}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            color: cs.onPrimary.withOpacity(0.80),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _TopIconButton(
                    icon: Icons.phone,
                    bg: cs.onPrimary.withOpacity(0.18),
                    fg: cs.onPrimary,
                    onTap: () => _toast(
                      "📞 Llamando (simulado) a ${widget.partnerName}...",
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RequiredLabel(text: "Tipo de Actividad", cs: cs),
                  const SizedBox(height: 10),

                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _activities.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.55,
                        ),
                    itemBuilder: (context, i) {
                      final item = _activities[i];
                      final selected = item.id == _selectedId;
                      return _ActivityCard(
                        emoji: item.emoji,
                        label: item.label,
                        selected: selected,
                        cs: cs,
                        onTap: () async {
                          setState(() {
                            _selectedId = item.id;
                            // si cambias de actividad, resetea tienda elegida
                            if (!_needsPlacePicker) _selectedLugar = null;
                          });

                          // si es tienda, abre selector premium
                          if (item.id == "tienda") {
                            await _openLugarPicker();
                          }
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 18),
                  _RequiredLabel(text: "Fecha", cs: cs),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      InkWell(
                        onTap: _openCalendar,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.calendar_month,
                            color: cs.onPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateField(
                          controller: _dayCtrl,
                          hint: "DD",
                          label: "Día",
                          maxLen: 2,
                          cs: cs,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "/",
                        style: textTheme.titleMedium?.copyWith(
                          color: cs.onSurface.withOpacity(0.45),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DateField(
                          controller: _monthCtrl,
                          hint: "MM",
                          label: "Mes",
                          maxLen: 2,
                          cs: cs,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "/",
                        style: textTheme.titleMedium?.copyWith(
                          color: cs.onSurface.withOpacity(0.45),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DateField(
                          controller: _yearCtrl,
                          hint: "AAAA",
                          label: "Año",
                          maxLen: 4,
                          cs: cs,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  _SoftTile(
                    cs: cs,
                    icon: Icons.event,
                    text: "O selecciona desde el calendario",
                    onTap: _openCalendar,
                  ),

                  const SizedBox(height: 16),
                  _RequiredLabel(text: "Hora", cs: cs),
                  const SizedBox(height: 10),
                  _SoftTile(
                    cs: cs,
                    icon: Icons.access_time,
                    text: _selectedTime == null
                        ? "Selecciona una hora (por defecto 18:30)"
                        : "Hora: ${_selectedTime!.format(context)}",
                    onTap: _openTimePicker,
                  ),

                  const SizedBox(height: 18),

                  // ✅ Lugar seleccionado (cuando es tienda)
                  if (_needsPlacePicker) ...[
                    _RequiredLabel(text: "Lugar elegido", cs: cs),
                    const SizedBox(height: 10),
                    _SoftTile(
                      cs: cs,
                      icon: Icons.storefront,
                      text: _selectedLugar == null
                          ? "Elige una tienda (recomendado)"
                          : "🏪 ${_selectedLugar!.displayName}",
                      onTap: _openLugarPicker,
                    ),
                    const SizedBox(height: 14),
                  ],

                  _RequiredLabel(text: "Lugar / Nota", cs: cs),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Ej: Plaza principal, Cafetería X, etc.",
                      filled: true,
                      fillColor: cs.surfaceVariant.withOpacity(0.6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: cs.outline.withOpacity(0.35),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: cs.outline.withOpacity(0.35),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: cs.primary),
                      ),
                    ),
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 18),
                  _PreviewCard(
                    cs: cs,
                    partnerName: widget.partnerName,
                    activity: _selectedActivity.label,
                    dateText: _prettyDateTimeOrEmpty(context),
                    placeText: _selectedLugar?.displayName,
                  ),

                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _createDateReal,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: cs.onPrimary,
                              ),
                            )
                          : const Text(
                              "Crear cita",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================= UI Components =================

class _RequiredLabel extends StatelessWidget {
  final String text;
  final ColorScheme cs;
  const _RequiredLabel({required this.text, required this.cs});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return RichText(
      text: TextSpan(
        style: textTheme.bodyMedium?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w800,
        ),
        children: [
          TextSpan(text: text),
          const TextSpan(
            text: " *",
            style: TextStyle(color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.cs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = selected ? cs.primary : cs.outline.withOpacity(0.25);
    final bg = selected ? cs.primary.withOpacity(0.10) : cs.surface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: selected ? 1.6 : 1.2),
          boxShadow: [
            BoxShadow(
              blurRadius: 10,
              offset: const Offset(0, 4),
              color: Colors.black.withOpacity(0.04),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                color: cs.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final int maxLen;
  final ColorScheme cs;

  const _DateField({
    required this.controller,
    required this.hint,
    required this.label,
    required this.maxLen,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 54,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        maxLength: maxLen,
        decoration: InputDecoration(
          counterText: "",
          labelText: label,
          hintText: hint,
          isDense: true,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          filled: true,
          fillColor: cs.surfaceVariant.withOpacity(0.6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.outline.withOpacity(0.35)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.outline.withOpacity(0.35)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: cs.primary),
          ),
        ),
        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color bg;
  final Color fg;

  const _TopIconButton({
    required this.icon,
    required this.onTap,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: fg),
      ),
    );
  }
}

class _SoftTile extends StatelessWidget {
  final ColorScheme cs;
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _SoftTile({
    required this.cs,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: cs.onSurface.withOpacity(0.65)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.75),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final ColorScheme cs;
  final String partnerName;
  final String activity;
  final String dateText;
  final String? placeText;

  const _PreviewCard({
    required this.cs,
    required this.partnerName,
    required this.activity,
    required this.dateText,
    this.placeText,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Vista previa",
            style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          _previewRow("Con:", partnerName, cs),
          const SizedBox(height: 6),
          _previewRow("Actividad:", activity, cs),
          const SizedBox(height: 6),
          _previewRow("Fecha:", dateText, cs),
          if (placeText != null && placeText!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            _previewRow("Lugar:", placeText!.trim(), cs),
          ],
        ],
      ),
    );
  }

  static Widget _previewRow(String k, String v, ColorScheme cs) {
    return Row(
      children: [
        SizedBox(
          width: 85,
          child: Text(
            k,
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.65),
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ================= Result Model + Dialog =================

class _ActivityItem {
  final String id;
  final String emoji;
  final String label;

  const _ActivityItem({
    required this.id,
    required this.emoji,
    required this.label,
  });
}

class _DateCreated {
  final String id;
  final String partnerName;
  final String activityLabel;
  final String activityId;
  final DateTime date;
  final DateTime createdAt;

  _DateCreated({
    required this.id,
    required this.partnerName,
    required this.activityLabel,
    required this.activityId,
    required this.date,
    required this.createdAt,
  });
}

class _SuccessDialog extends StatelessWidget {
  final _DateCreated created;
  const _SuccessDialog({required this.created});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final dd = created.date.day.toString().padLeft(2, "0");
    final mm = created.date.month.toString().padLeft(2, "0");
    final yyyy = created.date.year.toString();
    final hh = created.date.hour.toString().padLeft(2, "0");
    final mi = created.date.minute.toString().padLeft(2, "0");
    final dateText = "$dd/$mm/$yyyy $hh:$mi";

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.check_circle, color: cs.primary, size: 30),
            ),
            const SizedBox(height: 12),
            const Text(
              "¡Cita creada!",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              "Se creó la actividad con ${created.partnerName}.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: cs.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            _infoRow("Actividad", created.activityLabel, cs),
            const SizedBox(height: 8),
            _infoRow("Fecha", dateText, cs),
            const SizedBox(height: 8),
            _infoRow("ID", created.id, cs),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Listo",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _infoRow(String k, String v, ColorScheme cs) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            k,
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.65),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: TextStyle(
              color: cs.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
    );
  }
}
