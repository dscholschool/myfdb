
import 'package:flutter/services.dart' show rootBundle;
import 'package:myfdb/data/model/models.dart';

abstract interface class DataSource {
  Future<List<Team>?> loadTeams();
  Future<List<Match>?> loadMatches();
  Future<List<Player>?> loadPlayers();
  Future<List<MatchDetail>?> loadMatchDetails();
  Future<List<PlayerStat>?> loadPlayerStats();
}

class LocalDataSource implements DataSource {
  @override
  Future<List<Team>?> loadTeams() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/nation_teams.json');
      return parseList(jsonString, Team.fromJson);
    } catch (e) {
      print('Lỗi tải nation_teams.json: $e');
      return null;
    }
  }

  @override
  Future<List<Match>?> loadMatches() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/matches.json');
      return parseList(jsonString, Match.fromJson);
    } catch (e) {
      print('Lỗi tải matches.json: $e');
      return null;
    }
  }

  @override
  Future<List<Player>?> loadPlayers() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/players.json');
      return parseList(jsonString, Player.fromJson);
    } catch (e) {
      print('Lỗi tải players.json: $e');
      return null;
    }
  }

  @override
  Future<List<MatchDetail>?> loadMatchDetails() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/match_details.json');
      return parseList(jsonString, MatchDetail.fromJson);
    } catch (e) {
      print('Lỗi tải match_details.json: $e');
      return null;
    }
  }

  @override
  Future<List<PlayerStat>?> loadPlayerStats() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/player_stats.json');
      return parseList(jsonString, PlayerStat.fromJson);
    } catch (e) {
      print('Lỗi tải player_stats.json: $e');
      return null;
    }
  }
}