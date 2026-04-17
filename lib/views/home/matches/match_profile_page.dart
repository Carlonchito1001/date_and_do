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

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
    final cs = Theme.of(context).colorScheme;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              backgroundColor: cs.surface,
              title: const Text(
                "Reportar usuario",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Selecciona un motivo",
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withOpacity(0.45),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: detailsController,
                      enabled: !isSubmitting,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "Detalles adicionales",
                        hintText: "Cuéntanos qué pasó",
                        filled: true,
                        fillColor: cs.surfaceContainerHighest.withOpacity(0.45),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
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
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
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
      return const _MatchProfileSkeleton();
    }

    if (_error != null) {
      return _MatchProfileErrorState(message: _error!, onRetry: _loadProfile);
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
                expandedHeight: 500,
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
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

                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.08),
                              Colors.black.withOpacity(0.20),
                              Colors.black.withOpacity(0.78),
                            ],
                          ),
                        ),
                      ),

                      if (photos.length > 1)
                        Positioned(
                          top: 62,
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
                                color: Colors.black.withOpacity(0.42),
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
                          bottom: 120,
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
                        bottom: 28,
                        child: IgnorePointer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.otherUser.age.trim().isNotEmpty
                                    ? "${p.otherUser.fullName}, ${p.otherUser.age}"
                                    : p.otherUser.fullName,
                                style: textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (p.otherUser.city.isNotEmpty ||
                                      p.otherUser.country.isNotEmpty)
                                    _HeroInfoChip(
                                      icon: Icons.location_on_rounded,
                                      label:
                                          [
                                                p.otherUser.city,
                                                p.otherUser.country,
                                              ]
                                              .where((e) => e.trim().isNotEmpty)
                                              .join(", "),
                                    ),
                                  if ((p.ddProfile?.job.trim().isNotEmpty ??
                                      false))
                                    _HeroInfoChip(
                                      icon: Icons.work_rounded,
                                      label: p.ddProfile!.job,
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
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionCard(
                        title: "Sobre ${p.otherUser.fullName.split(' ').first}",
                        icon: Icons.favorite_outline_rounded,
                        child: Text(
                          _displayBio(p),
                          style: textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withOpacity(0.88),
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: "Detalles",
                        icon: Icons.badge_rounded,
                        child: Column(
                          children: [
                            _InfoRow(
                              icon: Icons.work_rounded,
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
                            const SizedBox(height: 14),
                            _InfoRow(
                              icon: Icons.favorite_outline_rounded,
                              label: "Busca",
                              value:
                                  (p.ddProfile?.lookingFor.trim().isNotEmpty ==
                                      true)
                                  ? p.ddProfile!.lookingFor
                                  : "No especificado",
                            ),
                            const SizedBox(height: 14),
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
                        icon: Icons.interests_rounded,
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
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: cs.outlineVariant.withOpacity(0.24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
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
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          "Llevan ${p.chatDaysCount} día(s) válidos de conversación. Necesitan 5 para crear una cita.",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.35,
                              ),
                        ),
                      ),
                  ],
                ),
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

  final Map<int, int> _quarterTurnsByIndex = {};

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

  int _currentTurns() => _quarterTurnsByIndex[_index] ?? 0;

  void _rotateLeft() {
    setState(() {
      _quarterTurnsByIndex[_index] = (_currentTurns() - 1) % 4;
    });
  }

  void _rotateRight() {
    setState(() {
      _quarterTurnsByIndex[_index] = (_currentTurns() + 1) % 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.photos.length;
    final currentTurns = ((_currentTurns() % 4) + 4) % 4;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text("${_index + 1} / $total"),
        actions: [
          IconButton(
            tooltip: "Girar izquierda",
            onPressed: _rotateLeft,
            icon: const Icon(Icons.rotate_left_rounded),
          ),
          IconButton(
            tooltip: "Girar derecha",
            onPressed: _rotateRight,
            icon: const Icon(Icons.rotate_right_rounded),
          ),
        ],
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
              final turns = (((_quarterTurnsByIndex[i] ?? 0) % 4) + 4) % 4;

              return Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: RotatedBox(
                    quarterTurns: turns,
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
          Positioned(
            bottom: 18,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: Text(
                  currentTurns == 0
                      ? "Desliza, haz zoom o gira la foto"
                      : "Rotación: ${currentTurns * 90}°",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
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
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(24),
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
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: cs.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withOpacity(0.55),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: cs.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: cs.onSurface, fontSize: 14, height: 1.45),
              children: [
                TextSpan(
                  text: "$label: ",
                  style: const TextStyle(fontWeight: FontWeight.w800),
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

class _HeroInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SinglePhotoViewerPage extends StatefulWidget {
  final String? base64;
  final String? url;

  const _SinglePhotoViewerPage({this.base64, this.url});

  @override
  State<_SinglePhotoViewerPage> createState() => _SinglePhotoViewerPageState();
}

class _SinglePhotoViewerPageState extends State<_SinglePhotoViewerPage> {
  int _quarterTurns = 0;

  void _rotateLeft() {
    setState(() {
      _quarterTurns = (_quarterTurns - 1) % 4;
    });
  }

  void _rotateRight() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    final turns = ((_quarterTurns % 4) + 4) % 4;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: "Girar izquierda",
            onPressed: _rotateLeft,
            icon: const Icon(Icons.rotate_left_rounded),
          ),
          IconButton(
            tooltip: "Girar derecha",
            onPressed: _rotateRight,
            icon: const Icon(Icons.rotate_right_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: RotatedBox(
                quarterTurns: turns,
                child: UserPhotoView(
                  base64String: widget.base64,
                  fallbackUrl: widget.url ?? '',
                  fit: BoxFit.contain,
                  errorWidget: const Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            left: 16,
            right: 16,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.10)),
                ),
                child: Text(
                  turns == 0
                      ? "Haz zoom o gira la foto"
                      : "Rotación: ${turns * 90}°",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
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

class _MatchProfileSkeleton extends StatefulWidget {
  const _MatchProfileSkeleton();

  @override
  State<_MatchProfileSkeleton> createState() => _MatchProfileSkeletonState();
}

class _MatchProfileSkeletonState extends State<_MatchProfileSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Column(
        children: [
          _ShimmerContainer(
            animation: _animation,
            child: Container(height: 430, color: cs.surfaceContainerHighest),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: List.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ShimmerContainer(
                    animation: _animation,
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                      ),
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

class _MatchProfileErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _MatchProfileErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cs.errorContainer.withOpacity(0.24),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: cs.error.withOpacity(0.14)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withOpacity(0.42),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 52,
                    color: cs.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "No se pudo cargar el perfil",
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => onRetry(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Reintentar"),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShimmerContainer extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const _ShimmerContainer({required this.animation, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.surfaceContainerHighest,
                cs.surfaceContainerHighest.withOpacity(0.5),
                cs.surfaceContainerHighest,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(
                slidePercent: animation.value,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
