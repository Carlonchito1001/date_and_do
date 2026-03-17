import 'package:date_and_doing/api/api_service.dart';
import 'alini_status_model.dart';

class AliniStatusService {
  final ApiService _api;

  AliniStatusService({ApiService? api}) : _api = api ?? ApiService();

  Future<AliniStatusModel> fetch(int matchId) async {
    final data = await _api.getAliniStatus(matchId);
    return AliniStatusModel.fromJson(data);
  }
}