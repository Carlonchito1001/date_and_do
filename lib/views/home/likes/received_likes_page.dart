import 'package:flutter/material.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';
import 'package:date_and_doing/widgets/user_photo_view.dart';
import 'package:date_and_doing/views/home/discover/widgets/new_match_screen.dart';

class ReceivedLikesPage extends StatefulWidget {
  const ReceivedLikesPage({super.key});

  @override
  State<ReceivedLikesPage> createState() => _ReceivedLikesPageState();
}

class _ReceivedLikesPageState extends State<ReceivedLikesPage> {
  final ApiService _api = ApiService();

  bool loading = true;
  bool sending = false;
  String? error;
  List<Map<String, dynamic>> likes = [];

  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  Future<void> _loadLikes() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await _api.getReceivedLikes();

      if (!mounted) return;
      setState(() {
        likes = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  Map<String, dynamic> _userFrom(Map<String, dynamic> item) {
    final user = item['user'];
    if (user is Map<String, dynamic>) return user;
    return {};
  }

  String _nameFrom(Map<String, dynamic> user) {
    return (user['use_txt_fullname'] ??
            user['fullname'] ??
            user['name'] ??
            'Usuario')
        .toString();
  }

  String _photoBase64From(Map<String, dynamic> user) {
    return (user['photo_preview_base64'] ?? '').toString();
  }

  String _photoFallbackFrom(Map<String, dynamic> user) {
    return (user['photo_fallback_url'] ??
            user['use_txt_avatar'] ??
            user['avatar'] ??
            '')
        .toString();
  }

  int _ageFrom(Map<String, dynamic> user) {
    return _asInt(user['use_txt_age'] ?? user['age']) ?? 0;
  }

  Future<void> _sendLike(Map<String, dynamic> item) async {
    if (sending) return;

    final user = _userFrom(item);
    final targetId = _asInt(user['use_int_id']);
    if (targetId == null) return;

    setState(() => sending = true);

    try {
      final token = await SharedPreferencesService().getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception("No hay sesión activa");
      }

      final res = await _api.likes(
        accessToken: token,
        targetUserId: targetId,
        type: "LIKE",
      );

      final match = res["match"];

      if (!mounted) return;

      setState(() {
        likes.remove(item);
      });

      if (match is Map<String, dynamic>) {
        final other = match["other_user"] as Map<String, dynamic>?;
        final name = _nameFrom(other ?? user);
        final photo = _photoFallbackFrom(other ?? user);

        final matchId = _asInt(match["ddm_int_id"] ?? match["id"] ?? match["match_id"]);
        final otherUserId = _asInt((other ?? user)["use_int_id"]);

        if (matchId != null && otherUserId != null) {
          final userInfo = await SharedPreferencesService().getUserInfo();
          final currentUserPhoto = userInfo?['use_txt_avatar']?.toString();

          if (!mounted) return;

          await Navigator.push(
            context,
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => NewMatchScreen(
                matchedUserName: name,
                matchedUserPhoto: photo,
                matchId: matchId,
                otherUserId: otherUserId,
                currentUserPhoto: currentUserPhoto,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error dando like: $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() => sending = false);
    }
  }

  Future<void> _pass(Map<String, dynamic> item) async {
    setState(() {
      likes.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 42),
              const SizedBox(height: 12),
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadLikes,
                child: const Text("Reintentar"),
              ),
            ],
          ),
        ),
      );
    }

    if (likes.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadLikes,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 120),
            Icon(Icons.favorite_border_rounded, size: 56),
            SizedBox(height: 14),
            Text(
              "Aún no tienes likes recibidos",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 8),
            Text(
              "Cuando alguien te dé like o superlike, aparecerá aquí.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLikes,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: likes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final item = likes[index];
          final user = _userFrom(item);

          final name = _nameFrom(user);
          final age = _ageFrom(user);
          final photoBase64 = _photoBase64From(user);
          final photoFallback = _photoFallbackFrom(user);
          final isSuperLike = item["is_superlike"] == true;

          return Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(24),
                  ),
                  child: SizedBox(
                    width: 118,
                    height: 150,
                    child: UserPhotoView(
                      base64String: photoBase64,
                      fallbackUrl: photoFallback,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        color: cs.primary.withOpacity(0.10),
                        alignment: Alignment.center,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : "U",
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isSuperLike)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              "Te dio SuperLike",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.blueAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        Text(
                          age > 0 ? "$name, $age" : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Quiere hacer match contigo",
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            IconButton.filledTonal(
                              onPressed: sending ? null : () => _pass(item),
                              icon: const Icon(Icons.close_rounded),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: sending ? null : () => _sendLike(item),
                                icon: const Icon(Icons.favorite_rounded),
                                label: const Text("Me gusta"),
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
          );
        },
      ),
    );
  }
}