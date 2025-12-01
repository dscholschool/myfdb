import 'dart:async';
import 'dart:math';
import 'package:myfdb/data/model/models.dart';
import 'package:myfdb/data/repository/repository.dart';

class TeamChartData {
  final double avgGoals;
  final double avgShotsOnTarget;
  final double avgPossession;
  final double avgPassAccuracy;
  final double defenseScore;
  final double disciplineScore;
  final double overallPossession;

  TeamChartData({
    required this.avgGoals,
    required this.avgShotsOnTarget,
    required this.avgPossession,
    required this.avgPassAccuracy,
    required this.defenseScore,
    required this.disciplineScore,
    required this.overallPossession,
  });
}

class TeamDetailViewModel {
  final _repository = DefaultRepository();

  final _matchesStream = StreamController<List<Match>>.broadcast();
  Stream<List<Match>> get matchesStream => _matchesStream.stream;
  final _playersStream = StreamController<List<Player>>.broadcast();
  Stream<List<Player>> get playersStream => _playersStream.stream;
  final _standingsStream = StreamController<List<TeamStanding>>.broadcast();
  Stream<List<TeamStanding>> get standingsStream => _standingsStream.stream;
  final _chartDataStream = StreamController<TeamChartData>.broadcast();
  Stream<TeamChartData> get chartDataStream => _chartDataStream.stream;

  void loadMatches(int teamId) {
    _repository.getMatchesForTeam(teamId).then((matches) {
      if (matches != null) {
        _matchesStream.sink.add(matches);
        _calculateChartData(teamId, matches);
      }
    });
  }

  void loadPlayers(int teamId) { _repository.getPlayersForTeam(teamId).then((p) { if (p != null) _playersStream.sink.add(p); }); }
  void loadStandings(String group) { _repository.getStandings().then((map) { if (map[group] != null) _standingsStream.sink.add(map[group]!); }); }

  void _calculateChartData(int teamId, List<Match> matches) async {
    final finishedMatches = matches.where((m) => m.status == 'FINISHED').toList();
    if (finishedMatches.isEmpty) return;

    final leagueStats = await _repository.getLeagueStats();

    List<MatchDetail> details = [];
    for (var m in finishedMatches) {
      var d = await _repository.getMatchDetails(m.matchId);
      if (d != null) details.add(d);
    }
    if (details.isEmpty) return;

    double tGoals=0, tSoT=0, tPoss=0, tPass=0, tConceded=0, tCards=0;
    for (int i = 0; i < details.length; i++) {
      var d = details[i];
      var m = finishedMatches.firstWhere((match) => match.matchId == d.matchId);
      bool isHome = m.homeTeamId == teamId;
      tGoals += (isHome ? m.score!.home : m.score!.away);
      tConceded += (isHome ? m.score!.away : m.score!.home);
      tSoT += (isHome ? d.shotsOnTarget.home : d.shotsOnTarget.away);
      tPoss += (isHome ? d.possession.home : d.possession.away);
      tPass += (isHome ? d.passAccuracy.home : d.passAccuracy.away);
      tCards += (isHome ? d.yellowCards.home : d.yellowCards.away) + (isHome ? d.redCards.home * 3 : d.redCards.away * 3);
    }
    int count = details.length;

    // 1. TÍNH GIÁ TRỊ THỰC (RAW VALUES)
    double avgGoals = tGoals / count;
    double avgSoT = tSoT / count;
    double avgPoss = tPoss / count;
    double avgPass = tPass / count;
    double avgConceded = tConceded / count;
    double avgCards = tCards / count;

    // 2. TÍNH ĐIỂM SỐ ĐỂ VẼ (SCORES 0-100) - Dùng logic Soft Cap & Sqrt
    double scoreGoals = (sqrt(avgGoals) / sqrt(leagueStats.maxAvgGoals) * 100).clamp(0, 100);
    double scoreSoT = (sqrt(avgSoT) / sqrt(leagueStats.maxAvgShotsOnTarget) * 100).clamp(0, 100);
    double scorePoss = (sqrt(avgPoss) / sqrt(leagueStats.maxAvgPossession) * 100).clamp(0, 100);
    double scorePass = (sqrt(avgPass) / sqrt(leagueStats.maxAvgPassAccuracy) * 100).clamp(0, 100);

    // Phòng ngự (Bàn thua): Max chấp nhận 2.5 bàn
    double scoreDefense = (100 - sqrt(avgConceded) / sqrt(2.5) * 100).clamp(0, 100);
    // Kỷ luật (Thẻ): Max chấp nhận 4 thẻ
    double scoreDiscipline = (100 - sqrt(avgCards) / sqrt(4.0) * 100).clamp(0, 100);

    final data = TeamChartData(
      avgGoals: scoreGoals,
      avgShotsOnTarget: scoreSoT,
      avgPossession: scorePoss,
      avgPassAccuracy: scorePass,
      defenseScore: scoreDefense,
      disciplineScore: scoreDiscipline,
      overallPossession: avgPoss,
    );
    _chartDataStream.sink.add(data);
  }

  void dispose() { _matchesStream.close(); _playersStream.close(); _standingsStream.close(); _chartDataStream.close(); }
}