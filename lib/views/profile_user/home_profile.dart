import 'package:date_and_doing/auth/google_auth_service.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';
import 'package:date_and_doing/views/login/dd_login.dart';
import 'package:date_and_doing/views/profile_user/config_profile.dart';
import 'package:date_and_doing/views/profile_user/edit_profile_page.dart';
import 'package:date_and_doing/views/profile_user/match_preferences_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeProfile extends StatefulWidget {
  const HomeProfile({super.key});

  @override
  State<HomeProfile> createState() => _HomeProfileState();
}

class _HomeProfileState extends State<HomeProfile> {
  String userName = '';
  String userEmail = '';
  String? avatarUrl;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _getInfoUser();
  }

  Future<void> _getInfoUser() async {
    final userInfo = await SharedPreferencesService().getUserInfo();

    if (!mounted) return;

    setState(() {
      if (userInfo != null) {
        userName = userInfo['use_txt_fullname'] ?? '';
        userEmail = userInfo['use_txt_email'] ?? '';
        avatarUrl = userInfo['use_txt_avatar'];
      }
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: cs.primary,
                    backgroundImage:
                        (avatarUrl != null && avatarUrl!.isNotEmpty)
                        ? NetworkImage(avatarUrl!)
                        : null,
                    child: (avatarUrl == null || avatarUrl!.isEmpty)
                        ? Text(
                            _getInitials(userName),
                            style: textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  // Positioned(
                  //   bottom: 4,
                  //   right: 4,
                  //   child: InkWell(
                  //     borderRadius: BorderRadius.circular(20),
                  //     onTap: () {},
                  //     child: Container(
                  //       padding: const EdgeInsets.all(6),
                  //       decoration: BoxDecoration(
                  //         shape: BoxShape.circle,
                  //         color: cs.primary,
                  //       ),
                  //       child: Icon(
                  //         Icons.camera_alt_rounded,
                  //         size: 18,
                  //         color: cs.onPrimary,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                userName.isNotEmpty ? userName : 'Usuario',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userEmail,
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),

              // _ProfileOptionCard(
              //   icon: Icons.brush_rounded,
              //   iconBgGradient: [
              //     cs.primary.withOpacity(0.18),
              //     cs.primaryContainer.withOpacity(0.35),
              //   ],
              //   iconColor: cs.primary,
              //   title: "Personalizar Avatar",
              //   subtitle: "Cambia tu foto de perfil",
              //   onTap: () {},
              // ),
              const SizedBox(height: 12),
              _ProfileOptionCard(
                icon: Icons.edit_note_rounded,
                iconBgGradient: [
                  cs.secondary.withOpacity(0.18),
                  cs.secondaryContainer.withOpacity(0.35),
                ],
                iconColor: cs.secondary,
                title: "Editar Perfil",
                subtitle: "Actualiza tu información personal",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditProfilePage()),
                  );
                },
              ),
              const SizedBox(height: 12),
              // _ProfileOptionCard(
              //   icon: Icons.settings_rounded,
              //   iconBgGradient: [
              //     Colors.orange.withOpacity(0.18),
              //     Colors.orangeAccent.withOpacity(0.35),
              //   ],
              //   iconColor: Colors.orange,
              //   title: "Configuración",
              //   subtitle: "Ajusta la configuración de tu cuenta",
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (_) => ConfigProfile()),
              //     );
              //   },
              // ),
              const SizedBox(height: 12),
              _ProfileOptionCard(
                icon: Icons.tune_rounded,
                iconBgGradient: [
                  Colors.teal.withOpacity(0.18),
                  Colors.tealAccent.withOpacity(0.35),
                ],
                iconColor: Colors.teal,
                title: "Preferencias",
                subtitle: "Personaliza tus preferencias de búsqueda",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MatchPreferencesPage()),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),
              _ProfileOptionCard(
                icon: Icons.logout_rounded,
                iconBgGradient: [
                  Colors.redAccent.withOpacity(0.18),
                  Colors.red.withOpacity(0.28),
                ],
                iconColor: Colors.redAccent,
                title: "Cerrar Sesión",
                subtitle: "Salir de tu cuenta",
                onTap: () => confirmLogout(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '?';

    final parts = clean
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();

    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }

    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

Future<void> logout(BuildContext context) async {
  await GoogleAuthService().signOut();
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const DdLogin()),
    (_) => false,
  );
}

Future<void> confirmLogout(BuildContext context) async {
  final cs = Theme.of(context).colorScheme;

  final bool? ok = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: cs.error),
            const SizedBox(width: 10),
            const Text("Cerrar sesión"),
          ],
        ),
        content: Text(
          "¿Seguro que deseas cerrar sesión? Tendrás que iniciar sesión nuevamente.",
          style: TextStyle(color: cs.onSurface.withOpacity(0.8)),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(
              foregroundColor: cs.onSurface.withOpacity(0.8),
            ),
            child: const Text("Cancelar"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text("Sí, cerrar"),
          ),
        ],
      );
    },
  );

  if (ok == true) {
    await logout(context);
  }
}

class _ProfileOptionCard extends StatelessWidget {
  final IconData icon;
  final List<Color> iconBgGradient;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileOptionCard({
    required this.icon,
    required this.iconBgGradient,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(colors: iconBgGradient),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }
}
