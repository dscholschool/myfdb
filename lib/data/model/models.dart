import 'dart:convert';

// Helper
List<T> parseList<T>(String responseBody, T Function(Map<String, dynamic>) fromJson) {
  final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<T>(fromJson).toList();
}

class Team {
  final int id;
  final String name;
  final String code;
  final String flagUrl;
  final String group;
  final String homeStadium;
  final int capacity;

  Team({
    required this.id,
    required this.name,
    required this.code,
    required this.flagUrl,
    required this.group,
    required this.homeStadium,
    required this.capacity,
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      flagUrl: json['flagUrl'],
      group: json['group'],
      homeStadium: json['homeStadium'],
      capacity: json['capacity'],
    );
  }
}

class Match {
  final String matchId;
  final String group;
  final int homeTeamId;
  final int awayTeamId;
  final String status;
  final DateTime date;
  final Score? score;
  Team? homeTeam;
  Team? awayTeam;

  Match({
    required this.matchId,
    required this.group,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.status,
    required this.date,
    this.score,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      matchId: json['matchId'],
      group: json['group'],
      homeTeamId: json['homeTeamId'],
      awayTeamId: json['awayTeamId'],
      status: json['status'],
      date: DateTime.parse(json['date']),
      score: json['score'] != null ? Score.fromJson(json['score']) : null,
    );
  }
}

class Score {
  final int home;
  final int away;
  Score({required this.home, required this.away});
  factory Score.fromJson(Map<String, dynamic> json) => Score(home: json['home'], away: json['away']);
}

class TeamStanding implements Comparable<TeamStanding> {
  final Team team;
  int mp = 0, w = 0, d = 0, l = 0, gf = 0, ga = 0, gd = 0, pts = 0;
  TeamStanding({required this.team});

  @override
  int compareTo(TeamStanding other) {
    if (pts != other.pts) return other.pts.compareTo(pts);
    if (gd != other.gd) return other.gd.compareTo(gd);
    if (gf != other.gf) return other.gf.compareTo(gf);
    return team.name.compareTo(other.team.name);
  }
}

class Player {
  final int playerId;
  final int teamId;
  final String name;
  final String position;
  final int jerseyNumber;
  final String imageUrl;
  Team? team;

  Player({
    required this.playerId,
    required this.teamId,
    required this.name,
    required this.position,
    required this.jerseyNumber,
    required this.imageUrl,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      playerId: json['playerId'],
      teamId: json['teamId'],
      name: json['name'],
      position: json['position'],
      jerseyNumber: json['jerseyNumber'],
      imageUrl: json['imageUrl'],
    );
  }
}

class PlayerStat {
  final String matchId;
  final int playerId;
  final int goal;
  final int assists;
  final int shotsOnTarget;
  final int missChances;
  final int keyPasses;
  final int passAccuracy;
  final int progressive;
  final int lostPossessionOnFinalThird;
  final int lostPossessionOutsideFinalThird;
  final int defenseAction;
  final int successfulTackles;
  final int aerialDueWon;
  final int errors;
  final int saves;
  final int savePercent;
  final int penaltySave;
  final int goalsConceded;

  Match? match;
  double? rating;

  PlayerStat({
    required this.matchId,
    required this.playerId,
    required this.goal,
    required this.assists,
    required this.shotsOnTarget,
    required this.missChances,
    required this.keyPasses,
    required this.passAccuracy,
    required this.progressive,
    required this.lostPossessionOnFinalThird,
    required this.lostPossessionOutsideFinalThird,
    required this.defenseAction,
    required this.successfulTackles,
    required this.aerialDueWon,
    required this.errors,
    required this.saves,
    required this.savePercent,
    required this.penaltySave,
    required this.goalsConceded,
    this.match,
    this.rating,
  });

  factory PlayerStat.fromJson(Map<String, dynamic> json) {
    return PlayerStat(
      matchId: json['MatchID'],
      playerId: json['PlayerID'],
      goal: json['Goal'],
      assists: json['Assists'],
      shotsOnTarget: json['ShotsOnTarget'],
      missChances: json['MissChances'],
      keyPasses: json['KeyPasses'],
      passAccuracy: json['PassAccuracy'],
      progressive: json['Progressive'],
      lostPossessionOnFinalThird: json['LostPossessionOnFinalThird'],
      lostPossessionOutsideFinalThird: json['LostPossessionOutsideFinalThird'],
      defenseAction: json['DefenseAction'],
      successfulTackles: json['SuccessfulTackles'],
      aerialDueWon: json['AerialDueWon'],
      errors: json['Errors'],
      saves: json['Saves'],
      savePercent: json['SavePercent'],
      penaltySave: json['PenaltySave'],
      goalsConceded: json['GoalsConceded'],
    );
  }
}

class MatchDetail {
  final String matchId;
  final StatPair possession;
  final StatPair shots;
  final StatPair shotsOnTarget;
  final StatPair passes;
  final StatPair passAccuracy;
  final StatPair fouls;
  final StatPair yellowCards;
  final StatPair redCards;
  final StatPair offsides;
  final StatPair corners;

  MatchDetail({
    required this.matchId,
    required this.possession,
    required this.shots,
    required this.shotsOnTarget,
    required this.passes,
    required this.passAccuracy,
    required this.fouls,
    required this.yellowCards,
    required this.redCards,
    required this.offsides,
    required this.corners,
  });

  factory MatchDetail.fromJson(Map<String, dynamic> json) {
    return MatchDetail(
      matchId: json['matchId'],
      possession: StatPair.fromJson(json['possession']),
      shots: StatPair.fromJson(json['shots']),
      shotsOnTarget: StatPair.fromJson(json['shotsOnTarget']),
      passes: StatPair.fromJson(json['passes']),
      passAccuracy: StatPair.fromJson(json['passAccuracy']),
      fouls: StatPair.fromJson(json['fouls']),
      yellowCards: StatPair.fromJson(json['yellowCards']),
      redCards: StatPair.fromJson(json['redCards']),
      offsides: StatPair.fromJson(json['offsides']),
      corners: StatPair.fromJson(json['corners']),
    );
  }
}

class StatPair {
  final int home;
  final int away;
  StatPair({required this.home, required this.away});
  factory StatPair.fromJson(Map<String, dynamic> json) => StatPair(home: (json['home'] as num).toInt(), away: (json['away'] as num).toInt());
}

class AggregatedPlayerStats {
  final int matchesPlayed;
  // Tấn công
  final int totalGoals;
  final int totalAssists;
  final int totalShotsOnTarget;
  final int totalMissChances;
  // Chuyền bóng
  final double avgPassAccuracy;
  final int totalKeyPasses;
  final int totalProgressive;
  // Phòng thủ
  final int totalDefenseActions;
  final int totalSuccessfulTackles;
  final int totalAerialDuelsWon;
  final int totalErrors;
  // Thủ môn
  final int totalSaves;
  final int totalGoalsConceded;
  final int cleanSheets;

  AggregatedPlayerStats({
    this.matchesPlayed = 0,
    this.totalGoals = 0,
    this.totalAssists = 0,
    this.totalShotsOnTarget = 0,
    this.totalMissChances = 0,
    this.avgPassAccuracy = 0.0,
    this.totalKeyPasses = 0,
    this.totalProgressive = 0,
    this.totalDefenseActions = 0,
    this.totalSuccessfulTackles = 0,
    this.totalAerialDuelsWon = 0,
    this.totalErrors = 0,
    this.totalSaves = 0,
    this.totalGoalsConceded = 0,
    this.cleanSheets = 0,
  });
}

// === CLASS DỰ ĐOÁN ===
class MatchPrediction {
  final double predictedTotalGoals;
  final String goalOverUnderLine;
  final double predictedTotalCards;
  final String cardOverUnderLine;
  final String handicapPick;

  final double predictedTotalCorners;
  final String cornerOverUnderLine;
  final String cornerHandicapPick;

  final String scorePrediction;
  final double winProbability;  // Home Win %
  final double drawProbability; // Draw %
  final double loseProbability; // Away Win %

  MatchPrediction({
    required this.predictedTotalGoals,
    required this.goalOverUnderLine,
    required this.predictedTotalCards,
    required this.cardOverUnderLine,
    required this.handicapPick,
    required this.predictedTotalCorners,
    required this.cornerOverUnderLine,
    required this.cornerHandicapPick,
    this.scorePrediction = "",
    this.winProbability = 0.0,
    this.drawProbability = 0.0,
    this.loseProbability = 0.0,
  });
}

// === MODEL THỐNG KÊ TOÀN GIẢI (ĐỂ LÀM MỐC SO SÁNH) ===
class LeagueStats {
  final double maxAvgGoals;
  final double maxAvgShotsOnTarget;
  final double maxAvgPossession;
  final double maxAvgPassAccuracy;

  LeagueStats({
    this.maxAvgGoals = 1.0,
    this.maxAvgShotsOnTarget = 1.0,
    this.maxAvgPossession = 100.0,
    this.maxAvgPassAccuracy = 100.0,
  });
}


