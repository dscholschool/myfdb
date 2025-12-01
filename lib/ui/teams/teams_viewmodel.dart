import 'dart:async';
import 'package:myfdb/data/model/models.dart';
import 'package:myfdb/data/repository/repository.dart';

class TeamsViewModel {
  final _repository = DefaultRepository();

  // Stream để giữ danh sách các đội tuyển
  final _teamsStream = StreamController<List<Team>>();
  Stream<List<Team>> get teamsStream => _teamsStream.stream;

  void loadTeams() {
    _repository.getAllTeams().then((teams) {
      if (teams != null) {
        _teamsStream.sink.add(teams);
      }
    });
  }

  void dispose() {
    _teamsStream.close();
  }
}