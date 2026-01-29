// dd_user.dart

class DdUser {
  final String id;
  final String nombre;
  final String email;
  final String provider; // google, facebook, phone, email
  final String? fotoUrl;
  final DateTime creadoEn;
  final bool esNuevo;

  DdUser({
    required this.id,
    required this.nombre,
    required this.email,
    required this.provider,
    this.fotoUrl,
    required this.creadoEn,
    required this.esNuevo,
  });

  @override
  String toString() {
    return 'DdUser(id: $id, nombre: $nombre, email: $email, provider: $provider, esNuevo: $esNuevo)';
  }
}
