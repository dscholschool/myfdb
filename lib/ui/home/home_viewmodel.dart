import 'dart:async';
import 'package:myfdb/data/model/models.dart';
import '../../data/repository/repository.dart';

class HomeViewModel {
  final _repository = DefaultRepository();

  // 1. Tạo 2 Stream, một cho mỗi danh sách
  final _finishedMatchesStream = StreamController<List<Match>>();
  final _scheduledMatchesStream = StreamController<List<Match>>();

  // 2. Cung cấp "đầu ra" cho UI
  Stream<List<Match>> get finishedMatches => _finishedMatchesStream.stream;
  Stream<List<Match>> get scheduledMatches => _scheduledMatchesStream.stream;

  void loadMatches() {
    // 3. Gọi Repository để lấy dữ liệu đã "join"
    _repository.loadMatchesForHome().then((matches) {
      if (matches != null) {
        // 4. Phân loại dữ liệu
        final finished = matches.where((m) => m.status == 'FINISHED').toList();
        final scheduled = matches.where((m) => m.status == 'SCHEDULED').toList();

        // 5. Đẩy 2 danh sách riêng biệt vào 2 Stream
        _finishedMatchesStream.sink.add(finished);
        _scheduledMatchesStream.sink.add(scheduled);
      }
    });
  }

  void dispose() {
    _finishedMatchesStream.close();
    _scheduledMatchesStream.close();
  }
}