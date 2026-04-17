import 'package:date_and_doing/config/app_config.dart';

class ApiEndpoints {
  // Base
  static String baseUrl = AppConfig.apiBase;

  // Login / auth
  static String login = '$baseUrl/auth/firebase/';
  static String infoUser = '$baseUrl/auth/me/';
  static String fcmToken = '$baseUrl/auth/users/';
  static String refreshToken = '$baseUrl/auth/token/refresh/';

  // Discover / swipes / matches / chat
  static String sugerenciasMatch(int maxDistanceKm, {int limit = 50}) =>
      '$baseUrl/dateanddo/discover/?radius_km=$maxDistanceKm&limit=$limit';

  static String swipes = '$baseUrl/dateanddo/swipes/';
  static String allMatches = '$baseUrl/dateanddo/matches/';
  static String allChats = '$baseUrl/dateanddo/messages/';
  static String messages = '$baseUrl/dateanddo/messages/';
  static String messagesByMatch(int matchId) => '${messages}?ddm_int_id=$matchId';
  static String messageById(int id) => '$baseUrl/dateanddo/messages/$id/';
  static String markMessagesAsRead = '$baseUrl/dateanddo/messages/mark_read/';

  // Perfil / usuario
  static String editarPerfil = '$baseUrl/auth/users/';
  static String onboardingProfile = '$baseUrl/dateanddo/user/onboarding/';
  static String userPhotos = '$baseUrl/dateanddo/user/photos/';
  static String matchProfile(int matchId) => '${allMatches}$matchId/profile/';

  // Preferencias
  static String preferencias = '$baseUrl/dateanddo/preferences/';
  static String preferences = '$baseUrl/dateanddo/preferences/';
  static String editPreferencias(int id) => '$baseUrl/auth/users/$id/';

  // Dates
  static String dates = '$baseUrl/dateanddo/dates/';
  static String dateById(int id) => '$baseUrl/dateanddo/dates/$id/';
  static String datesByMatch(int matchId) => '${dates}?ddm_int_id=$matchId';
  static String confirmDate(int dateId) => '$dates$dateId/confirm/';
  static String rejectDate(int dateId) => '$dates$dateId/reject/';
  static String completeDate(int dateId) => '$dates$dateId/complete/';
  static String cancelDate(int dateId) => '$dates$dateId/cancel/';
  static String rescheduleDate(int dateId) => '$dates$dateId/reschedule/';

  // Timeline / alini
  static String matchTimeline(int matchId) => '$allMatches$matchId/timeline/';
  static String aliniStatus(int matchId) =>
      '$baseUrl/dateanddo/matches/$matchId/alini_status/';

  // Settings / terms
  static String ddUserSettings = '$baseUrl/dateanddo/user/settings/';
  static String ddTerms = '$baseUrl/dateanddo/user/terms/';

  // Lugares externos
  static String lugares(String category) =>
      '${AppConfig.placesBase}?category=$category&limit=20';
}