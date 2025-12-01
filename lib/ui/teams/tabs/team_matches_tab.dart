import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfdb/data/model/models.dart';
import 'package:myfdb/ui/teams/team_detail_viewmodel.dart';
import 'package:myfdb/ui/match_detail/match_detail_page.dart';

class TeamMatchesTab extends StatefulWidget {
  final int teamId;
  final TeamDetailViewModel viewModel;

  const TeamMatchesTab({
    super.key,
    required this.teamId,
    required this.viewModel,
  });

  @override
  State<TeamMatchesTab> createState() => _TeamMatchesTabState();
}

class _TeamMatchesTabState extends State<TeamMatchesTab> with AutomaticKeepAliveClientMixin {

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadMatches(widget.teamId);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<List<Match>>(
      stream: widget.viewModel.matchesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Không có dữ liệu trận đấu.'));
        }

        final matches = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            return _MatchResultRow(match: matches[index]);
          },
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

// Widget con để vẽ 1 hàng kết quả
class _MatchResultRow extends StatelessWidget {
  final Match match;
  const _MatchResultRow({required this.match});

  @override
  Widget build(BuildContext context) {
    // Định dạng ngày: "Th 4, 5/11"
    final DateFormat dateFormatter = DateFormat('E, d/M', 'vi_VN');
    final DateFormat timeFormatter = DateFormat('HH:mm', 'vi_VN');

    final Team home = match.homeTeam!;
    final Team away = match.awayTeam!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
      color: Colors.white,
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MatchDetailPage(match: match),
              ),
            );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // Cột 1: Đội nhà (Cờ + Tên)
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _teamRow(context, home.flagUrl, home.name),
                    const SizedBox(height: 8),
                    _teamRow(context, away.flagUrl, away.name),
                  ],
                ),
              ),

              // Cột 2: Tỷ số
              Expanded(
                flex: 1,
                child: (match.status == 'FINISHED' && match.score != null)
                    ? Column(
                  children: [
                    Text(
                      match.score!.home.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      match.score!.away.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                )
                    : const SizedBox.shrink(),
              ),

              // Cột 3: Ngày/Giờ
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      match.status == 'FINISHED'
                          ? 'KT' // Vẫn là KT nếu đã đá
                          : timeFormatter.format(match.date.toLocal()), // Hiển thị giờ
                      style: TextStyle(
                        color: match.status == 'FINISHED' ? Colors.black : Colors.black, // Màu đỏ cho giờ sắp đá
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormatter.format(match.date.toLocal()),
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamRow(BuildContext context, String flagUrl, String name) {
    return Row(
      children: [
        Image.asset(
          flagUrl,
          width: 24,
          height: 18,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => const Icon(Icons.flag, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}