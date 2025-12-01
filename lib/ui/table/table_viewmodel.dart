import 'dart:async';
import 'package:myfdb/data/model/models.dart';
import '../../data/repository/repository.dart';

class TableViewModel {
  final _repository = DefaultRepository();

  // Stream này sẽ chứa cả 2 bảng A và B
  final _standingsStream = StreamController<Map<String, List<TeamStanding>>>();
  Stream<Map<String, List<TeamStanding>>> get standings => _standingsStream.stream;

  void loadStandings() {
    _repository.getStandings().then((standingsMap) {
      _standingsStream.sink.add(standingsMap);
    });
  }

  void dispose() {
    _standingsStream.close();
  }
}