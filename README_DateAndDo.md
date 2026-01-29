# Date & Doing (Date & Do) — App Móvil (Flutter)

App móvil tipo “match + chat + citas” donde los usuarios descubren perfiles (swipe), hacen match, conversan por chat y proponen/confirmar citas (dates). Incluye “History World” para visualizar el progreso de citas y un módulo de análisis del chat con IA (vía webhook externo).

---

## ✨ Características principales

- Autenticación con Firebase (token enviado al backend)
- Sesión con JWT (access/refresh) y refresh automático
- Discover / Swipe (Like, Dislike, Superlike)
- Matches basados en ddm_int_id
- Chat por match (mensajes persistentes)
- Citas (crear, confirmar, rechazar)
- History World (visualización gamificada)
- Análisis IA del chat (vía webhook)

---

## 🧱 Stack

- Flutter / Dart  
- Backend: https://services.fintbot.pe/api  
- Auth: Firebase + JWT  
- Persistencia local: shared_preferences  
- HTTP: http package  

---

## 📁 Estructura sugerida

lib/
  api/
    api_endpoints.dart
    api_service.dart
  services/
    shared_preferences_service.dart
  models/
    dd_date.dart
  views/
    discover/
    matches/
    chat/
    history/

---

## 🔐 Endpoints principales

- POST /auth/firebase/
- GET /dateanddo/discover/
- POST /dateanddo/swipes/
- GET /dateanddo/matches/
- GET /dateanddo/messages/?ddm_int_id={id}
- POST /dateanddo/messages/
- POST /dateanddo/dates/
- PATCH /dateanddo/dates/{id}/

---

## ▶️ Ejecución

flutter pub get  
flutter run  

---

## 📄 Licencia

Pendiente.
