class LugarLite {
  final String id;
  final String username;
  final String url;
  final String fullName;
  final String biography;
  final String profilePicUrl;

  LugarLite({
    required this.id,
    required this.username,
    required this.url,
    required this.fullName,
    required this.biography,
    required this.profilePicUrl,
  });

  factory LugarLite.fromApi(Map<String, dynamic> j) {
    return LugarLite(
      id: (j["id"] ?? "").toString(),
      username: (j["username"] ?? "").toString(),
      url: (j["url"] ?? "").toString(),
      fullName: (j["full_name"] ?? "").toString(),
      biography: (j["biography"] ?? "").toString(),
      profilePicUrl: (j["profile_pic_url"] ?? j["profile_pic_url_hd"] ?? "").toString(),
    );
  }

  String get displayName {
    final n = fullName.trim();
    if (n.isNotEmpty) return n;
    final u = username.trim();
    return u.isNotEmpty ? "@$u" : "Lugar";
  }
}
