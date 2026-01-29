// dd_mock_data.dart

/// Lista de matches (tarjetas)
const List<Map<String, dynamic>> ddMockMatches = [
  {
    "nombre": "Camila",
    "edad": 24,
    "foto": "https://images.pexels.com/photos/415829/pexels-photo-415829.jpeg",
    "status": "nuevo",
  },
  {
    "nombre": "Daniel",
    "edad": 27,
    "foto": "https://images.pexels.com/photos/614810/pexels-photo-614810.jpeg",
    "status": "activo",
  },
  {
    "nombre": "Sofía",
    "edad": 25,
    "foto": "https://images.pexels.com/photos/774909/pexels-photo-774909.jpeg",
    "status": "online",
  },
  {
    "nombre": "Juanita",
    "edad": 28,
    "foto": "https://images.pexels.com/photos/91227/pexels-photo-91227.jpeg",
    "status": "offline",
  },
];

/// Bandeja de mensajes (lista de conversaciones)
final List<Map<String, dynamic>> ddMockConversations = ddMockMatches.map((m) {
  final nombre = m["nombre"] as String;
  String ultimoMensaje;
  int noLeidos;

  switch (nombre) {
    case "Camila":
      ultimoMensaje = "Solo quiero un poco más de claridad, Juan. 💬";
      noLeidos = 2;
      break;
    case "Daniel":
      ultimoMensaje = "Te mandé la playlist, avísame qué tal. 🎧";
      noLeidos = 0;
      break;
    case "Sofía":
      ultimoMensaje = "¿Agendamos algo para el finde? 😉";
      noLeidos = 1;
      break;
    default:
      ultimoMensaje = "Nuevo match, ¡saluda! ✨";
      noLeidos = 1;
  }

  return {
    "nombre": nombre,
    "foto": m["foto"],
    "ultimoMensaje": ultimoMensaje,
    "hora": "22:14",
    "noLeidos": noLeidos,
  };
}).toList();

/// Historial de chat por persona (para inicializar el chat)
///
/// Estructura de cada mensaje:
/// {
///   "autor": "Juan" o "Camila",
///   "text": "...",
///   "hora": "7:41 PM",
///   "fecha": "2025-11-27"
/// }
Map<String, List<Map<String, dynamic>>> buildMockChatHistory() {
  final todayStr = DateTime.now().toIso8601String().substring(
    0,
    10,
  ); // yyyy-MM-dd

  return {
    "Camila": [
      {
        "autor": "Camila",
        "text": "Oye Juan, ayer estabas medio raro. ¿Todo bien?",
        "hora": "7:41 PM",
        "fecha": todayStr,
      },
      {
        "autor": "Juan",
        "text":
            "Sí Cami, solo estaba pensando en algunas cosas del trabajo y la familia.",
        "hora": "7:43 PM",
        "fecha": todayStr,
      },
      {
        "autor": "Camila",
        "text":
            "Pensé que quizá te había molestado algo que dije... me quedé con esa duda.",
        "hora": "7:45 PM",
        "fecha": todayStr,
      },
      {
        "autor": "Juan",
        "text":
            "No, para nada. De hecho me gusta que seas directa, solo a veces me cuesta procesar todo.",
        "hora": "7:48 PM",
        "fecha": todayStr,
      },
      {
        "autor": "Camila",
        "text":
            "Es que me importas, y no quiero estar invirtiendo mi energía en alguien que no sabe si quiere estar.",
        "hora": "7:51 PM",
        "fecha": todayStr,
      },
      {
        "autor": "Juan",
        "text":
            "Quiero estar, solo que voy más lento. Me da miedo apresurar algo y arruinarlo.",
        "hora": "7:55 PM",
        "fecha": todayStr,
      },
      {
        "autor": "Camila",
        "text":
            "No te pido correr, solo que lo que me dices y lo que haces vayan en la misma dirección.",
        "hora": "7:58 PM",
        "fecha": todayStr,
      },
      {
        "autor": "Juan",
        "text":
            "Tienes razón. A veces yo mismo me siento entre avanzar y frenar.",
        "hora": "8:01 PM",
        "fecha": todayStr,
      },
      {
        "autor": "Camila",
        "text":
            "Entonces solo te pido honestidad. Si en algún momento sientes que no quieres esto, dímelo.",
        "hora": "8:04 PM",
        "fecha": todayStr,
      },
      {
        "autor": "Juan",
        "text":
            "Ahora mismo sí quiero esto contigo. Solo necesito aprender a decirlo y demostrarlo mejor.",
        "hora": "8:08 PM",
        "fecha": todayStr,
      },
      {
        "autor": "Camila",
        "text":
            "Eso ya es un inicio. Gracias por decirlo. Yo sí quiero apostar por esto, pero no sola.",
        "hora": "8:12 PM",
        "fecha": todayStr,
      },
      {
        "autor": "Juan",
        "text":
            "No estarás sola. Solo tenme un poco de paciencia, Cami. Lo que siento por ti es real.",
        "hora": "8:15 PM",
        "fecha": todayStr,
      },
    ],

    // otras personas pueden tener chats más simples
    "Daniel": [
      {
        "autor": "Daniel",
        "text": "Te mandé la playlist de lo-fi, ¿la escuchaste? 🎧",
        "hora": "6:20 PM",
        "fecha": todayStr,
      },
      {
        "autor": "Juan",
        "text": "Sí, la estoy escuchando ahora mientras trabajo. Está buena.",
        "hora": "6:25 PM",
        "fecha": todayStr,
      },
    ],

    "Sofía": [
      {
        "autor": "Sofía",
        "text":
            "¿Agendamos algo para el finde? Tengo ganas de salir a caminar.",
        "hora": "5:10 PM",
        "fecha": todayStr,
      },
    ],
  };
}
