import 'dart:async';
import 'package:myfdb/data/model/models.dart';
import 'package:myfdb/data/repository/repository.dart';

class PlayersViewModel {
  final _repository = DefaultRepository();

  // Stream để giữ danh sách 110 cầu thủ
  final _playersStream = StreamController<List<Player>>();
  Stream<List<Player>> get playersStream => _playersStream.stream;

  void loadPlayers() {
    _repository.getAllPlayers().then((players) {
      if (players != null) {
        _playersStream.sink.add(players);
      }
    });
  }

  void dispose() {
    _playersStream.close();
  }
}