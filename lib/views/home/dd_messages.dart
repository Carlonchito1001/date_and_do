import 'package:flutter/material.dart';
import 'package:date_and_doing/api/api_service.dart';
import 'package:date_and_doing/services/shared_preferences_service.dart';
import 'dd_chat_page.dart';

class DdMessages extends StatefulWidget {
  const DdMessages({super.key});

  @override
  State<DdMessages> createState() => _DdMessagesState();
}

class _DdMessagesState extends State<DdMessages> {
  final _api = ApiService();
  final _prefs = SharedPreferencesService();

  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final myId = await _prefs.getUserIdOrThrow();

      // 1) Traer mensajes y matches
      final allMessages = await _api.getAllMessages();
      final allMatches = await _api.getAllMatches();

      // 2) Mapear matchId -> other_user
      final Map<int, Map<String, dynamic>> matchInfo = {};
      for (final m in allMatches) {
        final matchId = _asInt(m["ddm_int_id"]);
        if (matchId == null) continue;

        final other = m["other_user"];
        if (other is Map) {
          matchInfo[matchId] = {
            "otherUserId": _asInt(other["use_int_id"]) ?? 0,
            "nombre": (other["fullname"] ?? "Usuario").toString(),
            "foto": (other["photo"] ?? "https://via.placeholder.com/150")
                .toString(),
          };
        }
      }

      // 3) Agrupar mensajes por match
      final Map<int, List<Map<String, dynamic>>> grouped = {};
      for (final msg in allMessages) {
        if (msg["ddmsg_txt_status"] != "ACTIVO") continue;

        final matchId = _asInt(msg["ddm_int_id"]);
        if (matchId == null) continue;

        grouped.putIfAbsent(matchId, () => []);
        grouped[matchId]!.add(msg);
      }

      // 4) Construir conversaciones
      final List<Map<String, dynamic>> conversations = [];

      grouped.forEach((matchId, msgs) {
        msgs.sort((a, b) {
          final da = DateTime.parse(a["ddmsg_timestamp_datecreate"].toString());
          final db = DateTime.parse(b["ddmsg_timestamp_datecreate"].toString());
          return da.compareTo(db);
        });

        final last = msgs.last;
        final createdAt = DateTime.parse(
          last["ddmsg_timestamp_datecreate"].toString(),
        );

        final unread = msgs.where((m) {
          final receiver = _asInt(m["use_int_receiver"]);
          final read = m["ddmsg_bool_read"] == true;
          return receiver == myId && !read;
        }).length;

        int otherUserId = matchInfo[matchId]?["otherUserId"] ?? 0;
        if (otherUserId == 0) {
          final sender = _asInt(last["use_int_sender"]) ?? 0;
          final receiver = _asInt(last["use_int_receiver"]) ?? 0;
          otherUserId = sender == myId ? receiver : sender;
        }

        conversations.add({
          "matchId": matchId,
          "otherUserId": otherUserId,
          "nombre": matchInfo[matchId]?["nombre"] ?? "Chat #$matchId",
          "foto":
              matchInfo[matchId]?["foto"] ?? "https://via.placeholder.com/150",
          "ultimoMensaje": (last["ddmsg_txt_body"] ?? "").toString(),
          "hora": TimeOfDay.fromDateTime(createdAt).format(context),
          "noLeidos": unread,
          "timestamp": createdAt.millisecondsSinceEpoch,
        });
      });

      conversations.sort(
        (a, b) => (b["timestamp"] as int).compareTo(a["timestamp"] as int),
      );

      if (!mounted) return;
      setState(() {
        _conversations = conversations;
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

  int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  void _openChat(Map<String, dynamic> c) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DdChatPage(
          matchId: c["matchId"],
          otherUserId: c["otherUserId"],
          nombre: c["nombre"],
          foto: c["foto"],
        ),
      ),
    ).then((_) => _loadConversations());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Error: $_error"),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadConversations,
                child: const Text("Reintentar"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        child: ListView.separated(
          itemCount: _conversations.length,
          separatorBuilder: (_, __) => const Divider(indent: 72),
          itemBuilder: (context, i) {
            final chat = _conversations[i];

            return ListTile(
              onTap: () => _openChat(chat),
              leading: CircleAvatar(
                backgroundImage: NetworkImage(chat["foto"]),
              ),
              title: Text(chat["nombre"]),
              subtitle: Text(
                chat["ultimoMensaje"],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(chat["hora"], style: const TextStyle(fontSize: 11)),
                  if (chat["noLeidos"] > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.pinkAccent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        "${chat["noLeidos"]}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
