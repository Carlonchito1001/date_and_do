import 'dart:ui';
import 'package:date_and_doing/views/profile_user/home_profile.dart';
import 'package:flutter/material.dart';
import 'discover/dd_discover.dart';
import './dd_matches..dart';
import './dd_messages.dart';

class DdHome extends StatefulWidget {
  const DdHome({super.key});

  @override
  State<DdHome> createState() => _DdHomeState();
}

class _DdHomeState extends State<DdHome> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    DdDiscover(),
    DdMatches(),
    DdMessages(),
    HomeProfile(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final txt = theme.textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        elevation: 0,
        title: Text(
          "DATE ❤️ DO",
          style: txt.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: ElevatedButton(
              onPressed: () {},
              child: Text('Activar cuenta', style: TextStyle(fontSize: 10)),
            ),
          ),
          SizedBox(width: 10),
          CircleAvatar(child: Icon(Icons.person_rounded)),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications_outlined),
          ),
        ],
      ),

      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurface.withOpacity(0.5),
        backgroundColor: cs.surface,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            label: "Descubrir",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border_rounded),
            label: "Matches",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: "Mensajes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: "Perfil",
          ),
        ],
      ),
    );
  }
}
