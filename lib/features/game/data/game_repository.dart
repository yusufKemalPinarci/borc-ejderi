import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';

class GameRepository {
  GameRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'borc_ejderi_game_state_v1';

  Future<GameState> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return GameState.empty();
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return GameState.fromJson(map);
    } catch (_) {
      return GameState.empty();
    }
  }

  Future<void> save(GameState state) async {
    await _prefs.setString(_key, jsonEncode(state.toJson()));
  }
}
