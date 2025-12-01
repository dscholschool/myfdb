import 'dart:async';
import 'package:myfdb/data/model/models.dart';
import 'package:myfdb/data/repository/repository.dart';

class PlayerChartData {
  // Radar Data
  final double attackScore;
  final double defenseScore;
  final double creativityScore;
  final double technicalScore;
  final double tacticalScore;
  final int goals;
  final int assists;
  final int shots;
  final int totalPasses;
  final double passAccuracy;

  PlayerChartData({
    required this.attackScore,
    required this.defenseScore,
    required this.creativityScore,
    required this.technicalScore,
    required this.tacticalScore,
    required this.goals,
    required this.assists,
    required this.shots,
    required this.totalPasses,
    required this.passAccuracy,
  });
}

class PlayerDetailViewModel {
  final _repository = DefaultRepository();

  final _statsListStream = StreamController<List<PlayerStat>>.broadcast();
  Stream<List<PlayerStat>> get statsListStream => _statsListStream.stream;

  final _aggregatedStatsStream = StreamController<AggregatedPlayerStats>.broadcast();
  Stream<AggregatedPlayerStats> get aggregatedStatsStream => _aggregatedStatsStream.stream;

  final _chartDataStream = StreamController<PlayerChartData>.broadcast();
  Stream<PlayerChartData> get chartDataStream => _chartDataStream.stream;

  void loadPlayerStats(Player player) {
    _repository.getStatsForPlayer(player.playerId).then((stats) {
      if (stats != null) {
        _statsListStream.sink.add(stats);
      }
    });
  }

  void dispose() {
    _statsListStream.close();
    _aggregatedStatsStream.close();
    _chartDataStream.close();
  }
}