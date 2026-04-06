import 'package:flutter/material.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/views/home/dd_chat_page.dart';
import 'package:date_and_doing/views/home/discover/widgets/dd_create_activity_page.dart';
import 'package:date_and_doing/views/home/matches/match_profile_model.dart';
import 'package:date_and_doing/widgets/user_photo_view.dart';

const List<Map<String, String>> kReportReasons = [
  {"value": "SPAM", "label": "Spam"},
  {"value": "HARASSMENT", "label": "Acoso"},
  {"value": "FAKE_PROFILE", "label": "Perfil falso"},
  {"value": "INAPPROPRIATE_CONTENT", "label": "Contenido inapropiado"},
  {"value": "SCAM", "label": "Estafa"},
  {"value": "OTHER", "label": "Otro"},
];

class MatchProfilePage extends StatefulWidget {
  final int matchId;

  const MatchProfilePage({super.key, required this.matchId});

  @override
  State<MatchProfilePage> createState() => _MatchProfilePageState();
}

class _MatchProfilePageState extends State<MatchProfilePage> {
  final ApiService _api = ApiService();

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  bool _loading = true;
  String? _error;
  MatchProfileModel? _profile;
  int _photoIndex = 0;
  late final PageController _photoController;

  @override
  void initState() {
    super.initState();
    _photoController = PageController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await _api.getMatchProfile(widget.matchId);

      if (!mounted) return;
      setState(() {
        _profile = profile;
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

  Future<void> _showDateLockedDialog(MatchProfileModel p) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cita aún no disponible"),
        content: Text(
          "Para proponer una cita, ambos deben conversar durante al menos 5 días válidos.\n\n"
          "Un día válido cuenta solo si los dos enviaron al menos un mensaje ese día.\n\n"
          "Actualmente llevan ${p.chatDaysCount} día(s) válido(s).\n"
          "Les faltan ${p.remainingChatDaysForDate} día(s).",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Entendido"),
          ),
        ],
      ),
    );
  }

  String? _photoPreviewBase64(dynamic photo) {
    try {
      final v = photo.previewBase64;
      final s = (v ?? '').toString();
      return s.isNotEmpty ? s : null;
    } catch (_) {
      return null;
    }
  }

  String _photoFallbackUrl(dynamic photo) {
    try {
      final v = photo.url;
      return (v ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  void _openChat() {
    final p = _profile!;
    final photos = p.photos;
    final primaryPhoto = photos.isNotEmpty ? photos.first : null;

    final photoFallback = primaryPhoto != null
        ? _photoFallbackUrl(primaryPhoto)
        : (p.otherUser.avatar ?? "");

    final photoBase64 = primaryPhoto != null
        ? _photoPreviewBase64(primaryPhoto)
        : null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DdChatPage(
          matchId: p.matchId,
          otherUserId: p.otherUser.id,
          nombre: p.otherUser.fullName,
          foto: photoFallback,
          fotoBase64: photoBase64,
        ),
      ),
    );
  }

  void _openCreateDate() {
    final p = _profile!;

    if (!p.dateEnabled) {
      _showDateLockedDialog(p);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DdCreateActivityPage(
          matchId: p.matchId,
          partnerName: p.otherUser.fullName,
        ),
      ),
    );
  }

  Future<void> _showReportDialog() async {
    String selectedReason = "SPAM";
    final detailsController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text("Reportar usuario"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Selecciona un motivo"),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      items: kReportReasons
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e["value"],
                              child: Text(e["label"]!),
                            ),
                          )
                          .toList(),
                      onChanged: isSubmitting
                          ? null
                          : (value) {
                              if (value == null) return;
                              setLocalState(() {
                                selectedReason = value;
                              });
                            },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: detailsController,
                      enabled: !isSubmitting,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Detalles adicionales",
                        hintText: "Cuéntanos qué pasó",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text("Cancelar"),
                ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setLocalState(() {
                            isSubmitting = true;
                          });

                          try {
                            await _api.matchSafetyAction(
                              matchId: widget.matchId,
                              action: "report",
                              reason: selectedReason,
                              details: detailsController.text.trim(),
                            );

                            if (!mounted) return;
                            if (Navigator.of(dialogContext).canPop()) {
                              Navigator.of(dialogContext).pop();
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Reporte enviado correctamente"),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;

                            setLocalState(() {
                              isSubmitting = false;
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("No se pudo reportar: $e"),
                              ),
                            );
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Reportar"),
                ),
              ],
            );
          },
        );
      },
    );

    detailsController.dispose();
  }

  String _displayBio(MatchProfileModel p) {
    final ddBio = p.ddProfile?.bio.trim() ?? "";
    if (ddBio.isNotEmpty) return ddBio;

    final desc = p.otherUser.description?.trim() ?? "";
    if (desc.isNotEmpty) return desc;

    return "Aún no agregó una descripción.";
  }

  List<String> _buildInterests(MatchProfileModel p) {
    final raw = p.otherUser.interests?.trim() ?? "";
    if (raw.isEmpty) return [];
    return raw
        .split(RegExp(r'[,|/]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  void _openPhotoGallery(int initialIndex) {
    final p = _profile!;
    if (p.photos.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _PhotoGalleryPage(photos: p.photos, initialIndex: initialIndex),
      ),
    );
  }

  void _openSinglePhoto({String? base64, String? url}) {
    final hasBase64 = (base64 ?? '').trim().isNotEmpty;
    final hasUrl = (url ?? '').trim().isNotEmpty;
    if (!hasBase64 && !hasUrl) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _SinglePhotoViewerPage(
          base64: hasBase64 ? base64!.trim() : null,
          url: hasUrl ? url!.trim() : null,
        ),
      ),
    );
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
        appBar: AppBar(title: const Text("Detalle del match")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 56),
                const SizedBox(height: 12),
                Text(
                  "No se pudo cargar el perfil",
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadProfile,
                  child: const Text("Reintentar"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final p = _profile!;
    final photos = p.photos;
    final interests = _buildInterests(p);

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 460,
                pinned: true,
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == "report") {
                        await Future.delayed(const Duration(milliseconds: 120));
                        if (!mounted) return;
                        await _showReportDialog();
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem<String>(
                        value: "report",
                        child: Text("Reportar usuario"),
                      ),
                    ],
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (photos.isNotEmpty)
                        PageView.builder(
                          controller: _photoController,
                          physics: const BouncingScrollPhysics(
                            parent: PageScrollPhysics(),
                          ),
                          padEnds: false,
                          itemCount: photos.length,
                          onPageChanged: (index) {
                            setState(() => _photoIndex = index);
                          },
                          itemBuilder: (_, index) {
                            final photo = photos[index];
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _openPhotoGallery(index),
                              child: UserPhotoView(
                                base64String: _photoPreviewBase64(photo),
                                fallbackUrl: _photoFallbackUrl(photo),
                                fit: BoxFit.cover,
                                errorWidget: Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.broken_image_rounded,
                                    size: 80,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      else if ((p.otherUser.avatar ?? "").isNotEmpty)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () =>
                              _openSinglePhoto(url: p.otherUser.avatar),
                          child: UserPhotoView(
                            fallbackUrl: p.otherUser.avatar!,
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.person_rounded, size: 80),
                            ),
                          ),
                        )
                      else
                        Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.person_rounded, size: 90),
                        ),

                      IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.78),
                                Colors.black.withOpacity(0.22),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (photos.length > 1)
                        Positioned(
                          top: 60,
                          left: 16,
                          right: 16,
                          child: IgnorePointer(
                            child: Row(
                              children: List.generate(
                                photos.length,
                                (i) => Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                    ),
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: i == _photoIndex
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.35),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      if (photos.length > 1)
                        Positioned(
                          top: 74,
                          right: 16,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.45),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                "${_photoIndex + 1} / ${photos.length}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),

                      if (photos.length > 1)
                        Positioned(
                          bottom: 95,
                          left: 20,
                          child: IgnorePointer(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                "Desliza para ver más fotos",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),

                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 24,
                        child: IgnorePointer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.otherUser.age.trim().isNotEmpty
                                    ? "${p.otherUser.fullName}, ${p.otherUser.age}"
                                    : p.otherUser.fullName,
                                style: textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (p.otherUser.city.isNotEmpty ||
                                  p.otherUser.country.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        [p.otherUser.city, p.otherUser.country]
                                            .where((e) => e.trim().isNotEmpty)
                                            .join(", "),
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: Colors.white.withOpacity(0.92),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionCard(
                        title: "Sobre ${p.otherUser.fullName.split(' ').first}",
                        child: Text(
                          _displayBio(p),
                          style: textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withOpacity(0.85),
                            height: 1.45,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: "Detalles",
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: Icons.badge_rounded,
                              label: "Ocupación",
                              value:
                                  (p.ddProfile?.job.trim().isNotEmpty == true)
                                  ? p.ddProfile!.job
                                  : (p.otherUser.occupation
                                            ?.trim()
                                            .isNotEmpty ==
                                        true)
                                  ? p.otherUser.occupation!
                                  : "No especificado",
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.favorite_outline_rounded,
                              label: "Busca",
                              value:
                                  (p.ddProfile?.lookingFor.trim().isNotEmpty ==
                                      true)
                                  ? p.ddProfile!.lookingFor
                                  : "No especificado",
                            ),
                            const SizedBox(height: 12),
                            _InfoRow(
                              icon: Icons.person_outline_rounded,
                              label: "Género",
                              value:
                                  (p.ddProfile?.gender.trim().isNotEmpty ==
                                      true)
                                  ? p.ddProfile!.gender
                                  : (p.otherUser.gender?.trim().isNotEmpty ==
                                        true)
                                  ? p.otherUser.gender!
                                  : "No especificado",
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: "Intereses",
                        child: interests.isEmpty
                            ? Text(
                                "No se registraron intereses todavía.",
                                style: textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurface.withOpacity(0.7),
                                ),
                              )
                            : Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: interests
                                    .map(
                                      (e) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cs.primary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: cs.primary.withOpacity(0.18),
                                          ),
                                        ),
                                        child: Text(
                                          e,
                                          style: TextStyle(
                                            color: cs.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openCreateDate,
                          icon: const Icon(Icons.event_rounded),
                          label: Text(
                            p.dateEnabled
                                ? "Proponer cita"
                                : "Disponible en ${p.remainingChatDaysForDate} día(s)",
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _openChat,
                          icon: const Icon(Icons.chat_rounded),
                          label: const Text("Chatear"),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!p.dateEnabled)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "Llevan ${p.chatDaysCount} día(s) válidos de conversación. Necesitan 5 para crear una cita.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
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

class _PhotoGalleryPage extends StatefulWidget {
  final List<dynamic> photos;
  final int initialIndex;

  const _PhotoGalleryPage({required this.photos, required this.initialIndex});

  @override
  State<_PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends State<_PhotoGalleryPage> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  String? _preview(dynamic photo) {
    try {
      final s = (photo.previewBase64 ?? '').toString();
      return s.isNotEmpty ? s : null;
    } catch (_) {
      return null;
    }
  }

  String _url(dynamic photo) {
    try {
      return (photo.url ?? '').toString();
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.photos.length;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text("${_index + 1} / $total"),
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: total,
            onPageChanged: (value) {
              setState(() => _index = value);
            },
            itemBuilder: (_, i) {
              final photo = widget.photos[i];
              return Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: UserPhotoView(
                    base64String: _preview(photo),
                    fallbackUrl: _url(photo),
                    fit: BoxFit.contain,
                    errorWidget: const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              );
            },
          ),
          if (total > 1)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: List.generate(
                  total,
                  (i) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: 4,
                      decoration: BoxDecoration(
                        color: i == _index
                            ? Colors.white
                            : Colors.white.withOpacity(0.30),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: cs.onSurface, fontSize: 14, height: 1.4),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SinglePhotoViewerPage extends StatelessWidget {
  final String? base64;
  final String? url;

  const _SinglePhotoViewerPage({this.base64, this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4,
          child: UserPhotoView(
            base64String: base64,
            fallbackUrl: url ?? '',
            fit: BoxFit.contain,
            errorWidget: const Icon(
              Icons.broken_image_rounded,
              color: Colors.white,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}
