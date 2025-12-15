import 'dart:async';
import 'package:myfdb/data/model/models.dart';
import 'package:myfdb/data/repository/repository.dart';

class MatchDetailViewModel {
  final _repository = DefaultRepository();

  final _lineupStream = StreamController<Map<String, List<Player>>>();
  Stream<Map<String, List<Player>>> get lineupStream => _lineupStream.stream;
  final _detailsStream = StreamController<MatchDetail>();
  Stream<MatchDetail> get detailsStream => _detailsStream.stream;
  final _predictionStream = StreamController<MatchPrediction>();
  Stream<MatchPrediction> get predictionStream => _predictionStream.stream;

  void loadLineups(int homeTeamId, int awayTeamId) async {
    // Gọi repository 2 lần
    final homePlayers = await _repository.getPlayersForTeam(homeTeamId);
    final awayPlayers = await _repository.getPlayersForTeam(awayTeamId);

    // Đẩy vào stream
    if (homePlayers != null && awayPlayers != null) {
      _lineupStream.sink.add({
        'home': homePlayers,
        'away': awayPlayers,
      });
    }
  }

  void loadDetails(String matchId) {
    _repository.getMatchDetails(matchId).then((details) {
      if (details != null) {
        _detailsStream.sink.add(details);
      }
    });
  }

  // === HÀM LOAD DỰ ĐOÁN ===
  void loadPrediction(Match match) { // <-- Nhận tham số Match
    _repository.getMatchPrediction(match).then((prediction) { // <-- Truyền match vào repository
      if (prediction != null) {
        _predictionStream.sink.add(prediction);
      }
    });
  }

  void dispose() {
    _detailsStream.close();
    _lineupStream.close();
    _predictionStream.close();
  }
}