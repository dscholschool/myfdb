import 'dart:math';
import 'package:flutter/material.dart';
import 'package:myfdb/data/model/models.dart';
import 'package:myfdb/data/source/source.dart';

abstract interface class Repository {
  Future<List<Match>?> loadMatchesForHome();

  Future<Map<String, List<TeamStanding>>> getStandings();

  Future<List<Team>?> getAllTeams();

  Future<List<Player>?> getAllPlayers();

  Future<MatchDetail?> getMatchDetails(String matchId);

  Future<List<Player>?> getPlayersForTeam(int teamId);

  Future<List<Match>?> getMatchesForTeam(int teamId);

  Future<List<PlayerStat>?> getStatsForPlayer(int playerId);

  Future<MatchPrediction?> getMatchPrediction(Match match);

  Future<LeagueStats> getLeagueStats();
}

// (Helper Class giữ nguyên)
class _TeamFormStats {
  double gfShrunk = 0.0;
  double gaShrunk = 0.0;
  double avgYellowCards = 0.0;
  double avgFouls = 0.0;
  double avgCornersWon = 0.0;
  double avgCornersConceded = 0.0;
}

class DefaultRepository implements Repository {
  final LocalDataSource _localDataSource = LocalDataSource();

  List<Team> _cachedTeams = [];
  List<Match> _cachedMatches = [];
  List<Player> _cachedPlayers = [];
  List<MatchDetail> _cachedMatchDetails = [];
  List<PlayerStat> _cachedPlayerStats = [];
  LeagueStats? _cachedLeagueStats;

  final double _leagueAvgGoals = 1.875;
  final double _kShrinkage = 2.0;

  Future<void> _ensureDataLoaded() async {
    if (_cachedTeams.isEmpty ||
        _cachedMatches.isEmpty ||
        _cachedPlayers.isEmpty ||
        _cachedMatchDetails.isEmpty ||
        _cachedPlayerStats.isEmpty) {
      await Future.wait([
        _localDataSource.loadTeams().then((data) => _cachedTeams = data ?? []),
        _localDataSource.loadMatches().then(
          (data) => _cachedMatches = data ?? [],
        ),
        _localDataSource.loadPlayers().then(
          (data) => _cachedPlayers = data ?? [],
        ),
        _localDataSource.loadMatchDetails().then(
          (data) => _cachedMatchDetails = data ?? [],
        ),
        _localDataSource.loadPlayerStats().then(
          (data) => _cachedPlayerStats = data ?? [],
        ),
      ]);
      for (var player in _cachedPlayers) {
        player.team = _findTeamById(player.teamId);
      }
      for (var match in _cachedMatches) {
        match.homeTeam = _findTeamById(match.homeTeamId);
        match.awayTeam = _findTeamById(match.awayTeamId);
      }
    }
  }

  @override
  Future<List<Match>?> loadMatchesForHome() async {
    await _ensureDataLoaded();
    return _cachedMatches;
  }

  @override
  Future<List<Team>?> getAllTeams() async {
    await _ensureDataLoaded();
    return _cachedTeams;
  }

  @override
  Future<List<Player>?> getAllPlayers() async {
    await _ensureDataLoaded();
    return _cachedPlayers;
  }

  @override
  Future<MatchDetail?> getMatchDetails(String matchId) async {
    await _ensureDataLoaded();
    try {
      return _cachedMatchDetails.firstWhere((d) => d.matchId == matchId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Player>?> getPlayersForTeam(int teamId) async {
    await _ensureDataLoaded();
    return _cachedPlayers.where((p) => p.teamId == teamId).toList();
  }

  @override
  Future<List<Match>?> getMatchesForTeam(int teamId) async {
    await _ensureDataLoaded();
    final m = _cachedMatches
        .where((m) => m.homeTeamId == teamId || m.awayTeamId == teamId)
        .toList();
    m.sort((a, b) => b.date.compareTo(a.date));
    return m;
  }

  @override
  Future<Map<String, List<TeamStanding>>> getStandings() async {
    await _ensureDataLoaded();
    Map<int, TeamStanding> map = {};
    for (var t in _cachedTeams) map[t.id] = TeamStanding(team: t);
    final finished = _cachedMatches.where(
      (m) => m.status == 'FINISHED' && (m.group == 'A' || m.group == 'B'),
    );
    for (var m in finished) {
      var home = map[m.homeTeamId]!;
      var away = map[m.awayTeamId]!;
      home.mp++;
      away.mp++;
      home.gf += m.score!.home;
      home.ga += m.score!.away;
      away.gf += m.score!.away;
      away.ga += m.score!.home;
      home.gd = home.gf - home.ga;
      away.gd = away.gf - away.ga;
      if (m.score!.home > m.score!.away) {
        home.w++;
        home.pts += 3;
        away.l++;
      } else if (m.score!.home < m.score!.away) {
        away.w++;
        away.pts += 3;
        home.l++;
      } else {
        home.d++;
        away.d++;
        home.pts += 1;
        away.pts += 1;
      }
    }
    List<TeamStanding> a = map.values
        .where((s) => s.team.group == 'A')
        .toList();
    List<TeamStanding> b = map.values
        .where((s) => s.team.group == 'B')
        .toList();
    a.sort();
    b.sort();
    return {'A': a, 'B': b};
  }

  @override
  Future<List<PlayerStat>?> getStatsForPlayer(int playerId) async {
    await _ensureDataLoaded();
    final p = _findPlayerById(playerId);
    if (p == null) return [];
    final s = _cachedPlayerStats.where((s) => s.playerId == playerId).toList();
    if (s.isEmpty) return [];
    for (var stat in s) {
      stat.match = _findMatchById(stat.matchId);
      if (stat.match != null)
        stat.rating = _calculateRating(p, stat, stat.match!);
    }
    s.sort((a, b) {
      if (a.match == null || b.match == null) return 0;
      return b.match!.date.compareTo(a.match!.date);
    });
    return s;
  }

  // (Logic Rating Base 6.0)
  double _calculateRating(Player player, PlayerStat stat, Match match) {
    double baseRating = 6.0;
    double contribution = 0.0;
    bool isHomeTeam = player.teamId == match.homeTeamId;
    bool cleanSheet =
        (isHomeTeam && match.score!.away == 0) ||
        (!isHomeTeam && match.score!.home == 0);
    switch (player.position) {
      case 'Tiền đạo':

        contribution += min(1.2 * sqrt(stat.goal), 2.4);

        contribution += min(0.8 * stat.assists, 1.2);

        contribution += min(0.6 * sqrt(stat.shotsOnTarget), 1.2);

        contribution += min(0.9 * sqrt(stat.keyPasses), 1.0);

        contribution -= min(stat.missChances * 1.0, 2.0);

        int totalLost =
            stat.lostPossessionOnFinalThird +
            stat.lostPossessionOutsideFinalThird;

        contribution -= min(0.5 * sqrt(totalLost), 1.5);

        break;

      case 'Tiền vệ':
        contribution += min(1.2 * sqrt(stat.goal), 1.8);

        contribution += min(0.8 * stat.assists, 1.2);

        contribution += min(0.9 * sqrt(stat.keyPasses), 1.0);

        contribution += min(0.7 * sqrt(stat.progressive), 1.0);

        double passBonus = (stat.passAccuracy / 100.0 - 0.75) * 4;

        contribution += passBonus.clamp(-0.6, 0.6);

        int defenseActs = stat.successfulTackles + stat.defenseAction;

        contribution += min(0.6 * sqrt(defenseActs), 1.0);

        contribution -= min(
          0.5 * sqrt(stat.lostPossessionOutsideFinalThird),
          1.5,
        );

        contribution -= min(0.6 * sqrt(stat.lostPossessionOnFinalThird), 1.0);

        break;

      case 'Hậu vệ':
        int totalDefense = stat.defenseAction + stat.successfulTackles;

        contribution += min(0.5 * sqrt(totalDefense), 1.2);

        contribution += min(0.6 * sqrt(stat.successfulTackles), 1.0);

        contribution += min(0.4 * sqrt(stat.aerialDueWon), 0.8);

        contribution -= min(stat.errors * 1.5, 2.5);

        if (cleanSheet) contribution += 0.6;

        // Hậu vệ ghi bàn/kiến tạo được thưởng

        contribution += min(1.0 * sqrt(stat.goal), 2.5);

        contribution += min(1.2 * stat.assists, 1.8);

        break;

      case 'Thủ môn':
        contribution += min(0.6 * sqrt(stat.saves), 1.5);

        double saveBonus = (stat.savePercent / 100.0 - 0.6) * 3;

        contribution += saveBonus.clamp(-0.6, 0.6);

        contribution += stat.penaltySave * 1.5;

        contribution -= min(stat.goalsConceded * 0.8, 2.0);

        if (cleanSheet) contribution += 0.8;

        break;
    }

    double finalRating = baseRating + contribution;

    return finalRating.clamp(3.0, 10.0);
  }

  // ==================================================================
  // === PHẦN DỰ ĐOÁN (HANDICAP, GÓC, THẺ) ===
  // ==================================================================

  @override
  Future<MatchPrediction?> getMatchPrediction(Match match) async {
    await _ensureDataLoaded();

    final homeStats = await _calculateTeamForm(match.homeTeamId);
    final awayStats = await _calculateTeamForm(match.awayTeamId);

    // --- A. POISSON (BÀN THẮNG) ---
    double attackRelHome = homeStats.gfShrunk / _leagueAvgGoals;
    double defenseRelHome = homeStats.gaShrunk / _leagueAvgGoals;
    double attackRelAway = awayStats.gfShrunk / _leagueAvgGoals;
    double defenseRelAway = awayStats.gaShrunk / _leagueAvgGoals;
    double avgHomeGoals = 1.95;
    double avgAwayGoals = 1.80;

    double lambdaHome = attackRelHome * defenseRelAway * avgHomeGoals;
    double lambdaAway = attackRelAway * defenseRelHome * avgAwayGoals;

    final poissonResult = _calculatePoissonProbabilities(
      lambdaHome,
      lambdaAway,
    );

    // --- B. KÈO HANDICAP (LOGIC DỰA TRÊN CHÊNH LỆCH BÀN THẮNG KỲ VỌNG) ---
    double goalDiff = lambdaHome - lambdaAway;
    String handicapPick = "";

    if (goalDiff >= -1.75 && goalDiff < -1.5)
      handicapPick = "${match.homeTeam?.name} +1.5";
    else if (goalDiff >= -1.5 && goalDiff < -1.375)
      handicapPick = "${match.awayTeam?.name} -1.25";
    else if (goalDiff >= -1.375 && goalDiff < -1.25)
      handicapPick = "${match.homeTeam?.name} +1.25";
    else if (goalDiff >= -1.25 && goalDiff < -1.125)
      handicapPick = "${match.awayTeam?.name} -1";
    else if (goalDiff >= -1.125 && goalDiff < -1)
      handicapPick = "${match.homeTeam?.name} +1";
    else if (goalDiff >= -1 && goalDiff < -0.875)
      handicapPick = "${match.awayTeam?.name} -0.75";
    else if (goalDiff >= -0.875 && goalDiff < -0.75)
      handicapPick = "${match.homeTeam?.name} +0.75";
    else if (goalDiff >= -0.75 && goalDiff < -0.625)
      handicapPick = "${match.awayTeam?.name} -0.5";
    else if (goalDiff >= -0.625 && goalDiff < -0.5)
      handicapPick = "${match.homeTeam?.name} +0.5";
    else if (goalDiff > -0.5 && goalDiff < -0.375)
      handicapPick = "${match.awayTeam?.name} -0.25";
    else if (goalDiff >= -0.375 && goalDiff < -0.25)
      handicapPick = "${match.homeTeam?.name} +0.25";
    else if (goalDiff >= -0.25 && goalDiff <= 0.25)
      handicapPick = "Đồng banh (0)";
    else if (goalDiff > 0.25 && goalDiff <= 0.375)
      handicapPick = "${match.awayTeam?.name} +0.25";
    else if (goalDiff > 0.375 && goalDiff <= 0.5)
      handicapPick = "${match.homeTeam?.name} -0.25";
    else if (goalDiff > 0.5 && goalDiff <= 0.625)
      handicapPick = "${match.awayTeam?.name} +0.5";
    else if (goalDiff > 0.625 && goalDiff <= 0.75)
      handicapPick = "${match.homeTeam?.name} -0.5";
    else if (goalDiff > 0.75 && goalDiff <= 0.875)
      handicapPick = "${match.awayTeam?.name} +0.75";
    else if (goalDiff > 0.875 && goalDiff <= 1)
      handicapPick = "${match.homeTeam?.name} -0.75";
    else if (goalDiff > 1 && goalDiff <= 1.125)
      handicapPick = "${match.awayTeam?.name} +1";
    else if (goalDiff > 1.125 && goalDiff <= 1.25)
      handicapPick = "${match.homeTeam?.name} -1";
    else if (goalDiff > 1.25 && goalDiff <= 1.375)
      handicapPick = "${match.awayTeam?.name} +1.25";
    else if (goalDiff > 1.375 && goalDiff <= 1.5)
      handicapPick = "${match.homeTeam?.name} -1.25";
    else if (goalDiff > 1.5 && goalDiff <= 1.75)
      handicapPick = "${match.awayTeam?.name} +1.5";
    else if (goalDiff > 1.75)
      handicapPick = "${match.homeTeam?.name} -1.5";
    else
      handicapPick = "${match.awayTeam?.name} -1.5";




    // --- C. KÈO THẺ PHẠT ---
    double agrHome = homeStats.avgYellowCards + (homeStats.avgFouls * 0.1);
    double agrAway = awayStats.avgYellowCards + (awayStats.avgFouls * 0.1);
    double totalExpectedCards = agrHome + agrAway;
    String cardPick = "";

    if (totalExpectedCards > 3.75 && totalExpectedCards <= 4.25)
      cardPick = "Tài 3.5";
    else if(totalExpectedCards > 4.25 && totalExpectedCards <= 4.75)
      cardPick = "Xỉu 4.5";
    else if(totalExpectedCards > 4.75)
      cardPick = "Tài 4.5";
    else
      cardPick = "Xỉu 3.5";

    // --- D. KÈO PHẠT GÓC ---
    // Góc dự kiến Home = (Home Tấn công góc + Away Phòng thủ góc) / 2
    double expCornersHome =
        (homeStats.avgCornersWon + awayStats.avgCornersConceded) / 2;
    double expCornersAway =
        (awayStats.avgCornersWon + homeStats.avgCornersConceded) / 2;
    double totalExpectedCorners = expCornersHome + expCornersAway;
    double cornerDiff = expCornersHome - expCornersAway;

    // O/U Góc
    String cornerPick = "";
    if(totalExpectedCorners > 9.75 && totalExpectedCorners <= 10.25)
      cornerPick = "Tài 9.5 góc";
    else if(totalExpectedCorners > 10.25 && totalExpectedCorners <= 10.75)
      cornerPick = "Xỉu 10.5 góc";
    else if(totalExpectedCorners > 10.75)
      cornerPick = "Xỉu 10.5 góc";
    else
      cornerPick = "Xỉu 9.5 góc";


    // Handicap Góc
    String cornerHandicapPick = "";
    if (cornerDiff > 4.75)
      cornerHandicapPick = "${match.homeTeam?.name} -4.5 góc";
    else if (cornerDiff > 4.5 && cornerDiff <= 4.75)
      cornerHandicapPick = "${match.awayTeam?.name} +4.5 góc";
    else if (cornerDiff > 4.25 && cornerDiff <= 4.5)
      cornerHandicapPick = "${match.homeTeam?.name} -4 góc";
    else if (cornerDiff > 4 && cornerDiff <= 4.25)
      cornerHandicapPick = "${match.awayTeam?.name} +4 góc";
    else if (cornerDiff > 3.75 && cornerDiff <= 4)
      cornerHandicapPick = "${match.homeTeam?.name} -3.5 góc";
    else if (cornerDiff > 3.5 && cornerDiff <= 3.75)
      cornerHandicapPick = "${match.awayTeam?.name} +3.5 góc";
    else if (cornerDiff > 3.25 && cornerDiff <= 3.5)
      cornerHandicapPick = "${match.homeTeam?.name} -3 góc";
    else if (cornerDiff > 3 && cornerDiff <= 3.25)
      cornerHandicapPick = "${match.awayTeam?.name} +3 góc";
    else if (cornerDiff > 2.75 && cornerDiff <= 3)
      cornerHandicapPick = "${match.homeTeam?.name} -2.5 góc";
    else if (cornerDiff > 2.5 && cornerDiff <= 2.75)
      cornerHandicapPick = "${match.awayTeam?.name} +2.5 góc";
    else if (cornerDiff > 2.25 && cornerDiff <= 2.5)
      cornerHandicapPick = "${match.homeTeam?.name} -2 góc";
    else if (cornerDiff > 2 && cornerDiff <= 2.25)
      cornerHandicapPick = "${match.awayTeam?.name} +2 góc";
    else if (cornerDiff > 1.75 && cornerDiff <= 2)
      cornerHandicapPick = "${match.homeTeam?.name} -1.5 góc";
    else if (cornerDiff > 1.5 && cornerDiff <= 1.75)
      cornerHandicapPick = "${match.awayTeam?.name} +1.5 góc";
    else if (cornerDiff > 1.25 && cornerDiff <= 1.5)
      cornerHandicapPick = "${match.homeTeam?.name} -1 góc";
    else if (cornerDiff > 1 && cornerDiff <= 1.25)
      cornerHandicapPick = "${match.awayTeam?.name} +1 góc";
    else if (cornerDiff > 0.75 && cornerDiff <= 1)
      cornerHandicapPick = "${match.homeTeam?.name} -0.5 góc";
    else if (cornerDiff > 0.5 && cornerDiff <= 0.75)
      cornerHandicapPick = "${match.awayTeam?.name} +0.5 góc";
    else if (cornerDiff >= -0.5 && cornerDiff <= 0.5)
      cornerHandicapPick = "${match.homeTeam?.name} +0 góc";
    else if (cornerDiff < -0.5 && cornerDiff >= -0.75)
      cornerHandicapPick = "${match.homeTeam?.name} +0.5 góc";
    else if (cornerDiff < -0.75 && cornerDiff >= -1)
      cornerHandicapPick = "${match.awayTeam?.name} -0.5 góc";
    else if (cornerDiff < -1 && cornerDiff >= -1.25)
      cornerHandicapPick = "${match.homeTeam?.name} +1 góc";
    else if (cornerDiff < -1.25 && cornerDiff >= -1.5)
      cornerHandicapPick = "${match.awayTeam?.name} -1 góc";
    else if (cornerDiff < -1.5 && cornerDiff >= -1.75)
      cornerHandicapPick = "${match.homeTeam?.name} +1.5 góc";
    else if (cornerDiff < -1.75 && cornerDiff >= -2)
      cornerHandicapPick = "${match.awayTeam?.name} -1.5 góc";
    else if (cornerDiff < -2 && cornerDiff >= -2.25)
      cornerHandicapPick = "${match.homeTeam?.name} +2 góc";
    else if (cornerDiff < -2.25 && cornerDiff >= -2.5)
      cornerHandicapPick = "${match.awayTeam?.name} -2 góc";
    else if (cornerDiff < -2.5 && cornerDiff >= -2.5)
      cornerHandicapPick = "${match.homeTeam?.name} +2.5 góc";
    else if (cornerDiff < -2.75 && cornerDiff >= -3)
      cornerHandicapPick = "${match.awayTeam?.name} -2.5 góc";
    else if (cornerDiff < -3 && cornerDiff >= -3.25)
      cornerHandicapPick = "${match.homeTeam?.name} +3 góc";
    else if (cornerDiff < -3.25 && cornerDiff >= -3.5)
      cornerHandicapPick = "${match.awayTeam?.name} -3 góc";
    else if (cornerDiff < -3.5 && cornerDiff >= -3.5)
      cornerHandicapPick = "${match.homeTeam?.name} +3.5 góc";
    else if (cornerDiff < -3.75 && cornerDiff >= -4)
      cornerHandicapPick = "${match.awayTeam?.name} -3.5 góc";
    else if (cornerDiff < -4 && cornerDiff >= -4.25)
      cornerHandicapPick = "${match.homeTeam?.name} +4 góc";
    else if (cornerDiff < -4.25 && cornerDiff >= -4.5)
      cornerHandicapPick = "${match.awayTeam?.name} -4 góc";
    else if (cornerDiff < -4.5 && cornerDiff >= -4.5)
      cornerHandicapPick = "${match.homeTeam?.name} +4.5 góc";
    else if (cornerDiff < -4.75 && cornerDiff >= -5)
      cornerHandicapPick = "${match.awayTeam?.name} -4.5 góc";
    else
      cornerHandicapPick = "${match.homeTeam?.name} 5 góc";


    return MatchPrediction(
      predictedTotalGoals: lambdaHome + lambdaAway,
      goalOverUnderLine: (lambdaHome + lambdaAway) > 3
          ? "Tài 2.5"
          : "Xỉu 2.5",
      predictedTotalCards: totalExpectedCards,
      cardOverUnderLine: cardPick,
      handicapPick: handicapPick,
      predictedTotalCorners: totalExpectedCorners,
      cornerOverUnderLine: cornerPick,
      cornerHandicapPick: cornerHandicapPick,

      scorePrediction:
          "${poissonResult.mostLikelyScoreHome} - ${poissonResult.mostLikelyScoreAway}",
      winProbability: poissonResult.winProb * 100,
      drawProbability: poissonResult.drawProb * 100,
      loseProbability: poissonResult.loseProb * 100,
    );
  }

  Future<_TeamFormStats> _calculateTeamForm(int teamId) async {
    final teamMatches = _cachedMatches
        .where(
          (m) =>
              (m.homeTeamId == teamId || m.awayTeamId == teamId) &&
              m.status == 'FINISHED',
        )
        .toList();
    if (teamMatches.isEmpty) return _TeamFormStats();
    double sumGF = 0, sumGA = 0, sumY = 0, sumF = 0, sumCW = 0, sumCC = 0;
    for (var m in teamMatches) {
      final detail = _cachedMatchDetails.firstWhere(
        (d) => d.matchId == m.matchId,
        orElse: () => MatchDetail(
          matchId: '',
          possession: StatPair(home: 0, away: 0),
          shots: StatPair(home: 0, away: 0),
          shotsOnTarget: StatPair(home: 0, away: 0),
          passes: StatPair(home: 0, away: 0),
          passAccuracy: StatPair(home: 0, away: 0),
          fouls: StatPair(home: 0, away: 0),
          yellowCards: StatPair(home: 0, away: 0),
          redCards: StatPair(home: 0, away: 0),
          offsides: StatPair(home: 0, away: 0),
          corners: StatPair(home: 0, away: 0),
        ),
      );
      bool isHome = m.homeTeamId == teamId;
      if (isHome) {
        sumGF += m.score!.home;
        sumGA += m.score!.away;
        sumY += detail.yellowCards.home;
        sumF += detail.fouls.home;
        sumCW += detail.corners.home;
        sumCC += detail.corners.away;
      } else {
        sumGF += m.score!.away;
        sumGA += m.score!.home;
        sumY += detail.yellowCards.away;
        sumF += detail.fouls.away;
        sumCW += detail.corners.away;
        sumCC += detail.corners.home;
      }
    }
    int n = teamMatches.length;
    _TeamFormStats stats = _TeamFormStats();
    stats.gfShrunk =
        (sumGF + _kShrinkage * _leagueAvgGoals) / (n + _kShrinkage);
    stats.gaShrunk =
        (sumGA + _kShrinkage * _leagueAvgGoals) / (n + _kShrinkage);
    stats.avgYellowCards = sumY / n;
    stats.avgFouls = sumF / n;
    stats.avgCornersWon = sumCW / n;
    stats.avgCornersConceded = sumCC / n;
    return stats;
  }

  _PoissonResult _calculatePoissonProbabilities(
    double lambdaHome,
    double lambdaAway,
  ) {
    double maxProb = -1.0;
    int bestHome = 0;
    int bestAway = 0;
    double win = 0, draw = 0, lose = 0;
    for (int i = 0; i <= 6; i++) {
      for (int j = 0; j <= 6; j++) {
        double p = _poisson(i, lambdaHome) * _poisson(j, lambdaAway);
        if (p > maxProb) {
          maxProb = p;
          bestHome = i;
          bestAway = j;
        }
        if (i > j)
          win += p;
        else if (i == j)
          draw += p;
        else
          lose += p;
      }
    }
    return _PoissonResult(bestHome, bestAway, win, draw, lose);
  }

  double _poisson(int k, double lambda) {
    return (pow(lambda, k) * exp(-lambda)) / _factorial(k);
  }

  int _factorial(int n) {
    if (n == 0) return 1;
    return n * _factorial(n - 1);
  }

  @override
  Future<LeagueStats> getLeagueStats() async {
    await _ensureDataLoaded();
    if (_cachedLeagueStats != null) return _cachedLeagueStats!;

    double maxGoals = 0;
    double maxSoT = 0;
    double maxPossession = 0;
    double maxPassAcc = 0;

    // Duyệt qua từng đội để tính trung bình của họ
    for (var team in _cachedTeams) {
      var matches = _cachedMatches.where((m) => m.status == 'FINISHED' && (m.homeTeamId == team.id || m.awayTeamId == team.id)).toList();
      if (matches.isEmpty) continue;

      double tGoals=0, tSoT=0, tPoss=0, tPass=0;

      for (var m in matches) {
        var d = _cachedMatchDetails.firstWhere((d) => d.matchId == m.matchId, orElse: () => MatchDetail(matchId: '', possession: StatPair(home:0, away:0), shots: StatPair(home:0, away:0), shotsOnTarget: StatPair(home:0, away:0), passes: StatPair(home:0, away:0), passAccuracy: StatPair(home:0, away:0), fouls: StatPair(home:0, away:0), yellowCards: StatPair(home:0, away:0), redCards: StatPair(home:0, away:0), offsides: StatPair(home:0, away:0), corners: StatPair(home:0, away:0)));
        bool isHome = m.homeTeamId == team.id;
        tGoals += isHome ? m.score!.home : m.score!.away;
        tSoT += isHome ? d.shotsOnTarget.home : d.shotsOnTarget.away;
        tPoss += isHome ? d.possession.home : d.possession.away;
        tPass += isHome ? d.passAccuracy.home : d.passAccuracy.away;
      }

      double avgG = tGoals / matches.length;
      double avgS = tSoT / matches.length;
      double avgP = tPoss / matches.length;
      double avgPA = tPass / matches.length;

      if (avgG > maxGoals) maxGoals = avgG;
      if (avgS > maxSoT) maxSoT = avgS;
      if (avgP > maxPossession) maxPossession = avgP;
      if (avgPA > maxPassAcc) maxPassAcc = avgPA;
    }

    // Fallback an toàn
    if (maxGoals == 0) maxGoals = 2.0;
    if (maxSoT == 0) maxSoT = 5.0;
    if (maxPossession == 0) maxPossession = 60.0;
    if (maxPassAcc == 0) maxPassAcc = 85.0;

    _cachedLeagueStats = LeagueStats(
      maxAvgGoals: maxGoals,
      maxAvgShotsOnTarget: maxSoT,
      maxAvgPossession: maxPossession,
    );

    return _cachedLeagueStats!;
  }

  double normalize(double value, double min, double max) {
    if (max == min) return 50; // tránh chia 0
    return ((value - min) / (max - min)) * 100;
  }

  Team? _findTeamById(int teamId) {
    try {
      return _cachedTeams.firstWhere((t) => t.id == teamId);
    } catch (e) {
      return null;
    }
  }

  Player? _findPlayerById(int playerId) {
    try {
      return _cachedPlayers.firstWhere((p) => p.playerId == playerId);
    } catch (e) {
      return null;
    }
  }

  Match? _findMatchById(String matchId) {
    try {
      final match = _cachedMatches.firstWhere((m) => m.matchId == matchId);
      if (match.homeTeam == null) {
        match.homeTeam = _findTeamById(match.homeTeamId);
        match.awayTeam = _findTeamById(match.awayTeamId);
      }
      return match;
    } catch (e) {
      return null;
    }
  }
}

class _PoissonResult {
  final int mostLikelyScoreHome;
  final int mostLikelyScoreAway;
  final double winProb;
  final double drawProb;
  final double loseProb;

  _PoissonResult(
    this.mostLikelyScoreHome,
    this.mostLikelyScoreAway,
    this.winProb,
    this.drawProb,
    this.loseProb,
  );
}

class LeagueMinMaxStats {
  final double minAvgGoals;
  final double maxAvgGoals;

  final double minAvgShotsOnTarget;
  final double maxAvgShotsOnTarget;

  final double minAvgPossession;
  final double maxAvgPossession;

  final double minAvgPassAccuracy;
  final double maxAvgPassAccuracy;

  final double minAvgConceded;
  final double maxAvgConceded;

  final double minAvgCards;
  final double maxAvgCards;

  LeagueMinMaxStats({
    required this.minAvgGoals,
    required this.maxAvgGoals,
    required this.minAvgShotsOnTarget,
    required this.maxAvgShotsOnTarget,
    required this.minAvgPossession,
    required this.maxAvgPossession,
    required this.minAvgPassAccuracy,
    required this.maxAvgPassAccuracy,
    required this.minAvgConceded,
    required this.maxAvgConceded,
    required this.minAvgCards,
    required this.maxAvgCards
  });
}

