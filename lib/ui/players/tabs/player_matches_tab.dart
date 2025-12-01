import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfdb/data/model/models.dart';
import 'package:myfdb/ui/players/player_detail_viewmodel.dart';
import 'package:myfdb/ui/players/player_match_stats_page.dart';

class PlayerMatchesTab extends StatefulWidget {
  final Player player;
  final PlayerDetailViewModel viewModel;

  const PlayerMatchesTab({
    super.key,
    required this.player,
    required this.viewModel,
  });

  @override
  State<PlayerMatchesTab> createState() => _PlayerMatchesTabState();
}

class _PlayerMatchesTabState extends State<PlayerMatchesTab> with AutomaticKeepAliveClientMixin {

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadPlayerStats(widget.player);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<List<PlayerStat>>(
      stream: widget.viewModel.statsListStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.update, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "Ứng dụng đang được cập nhật.\nDữ liệu sẽ sớm được hiển thị",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final stats = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: stats.length,
          itemBuilder: (context, index) {
            // === SỬA: Truyền cả Player VÀ Stat ===
            return _MatchResultCard(player: widget.player, stat: stats[index]);
          },
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

// Widget con để vẽ 1 Card kết quả
class _MatchResultCard extends StatelessWidget {
  final Player player; // <-- Cần Player
  final PlayerStat stat; // <-- Cần Stat
  const _MatchResultCard({required this.player, required this.stat});

  Color _getRatingColor(double rating) {
    if (rating >= 8.0) return Colors.blue.shade400;
    if (rating >= 7.0) return Colors.green.shade400;
    if (rating >= 6.0) return Colors.orange.shade400;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('dd/MM/yy', 'vi_VN');

    final Match? match = stat.match;
    if (match == null || match.homeTeam == null || match.awayTeam == null) {
      return const Card(child: Text('Lỗi tải dữ liệu trận đấu'));
    }

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
              // Tới trang mới (Diogo Costa)
              builder: (context) => PlayerMatchStatsPage(
                player: player,
                stat: stat, // Truyền dữ liệu stat
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // (Cột 1: Ngày)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatter.format(match.date.toLocal()),
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'KT',
                    style: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // (Cột 2: Đội)
              Expanded(
                child: Column(
                  children: [
                    _teamRow(context, home.flagUrl, home.name),
                    const SizedBox(height: 8),
                    _teamRow(context, away.flagUrl, away.name),
                  ],
                ),
              ),

              // (Cột 3: Tỷ số)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
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
                ),
              ),

              // (Cột 4: Rating)
              Container(
                width: 40,
                height: 30,
                decoration: BoxDecoration(
                  color: _getRatingColor(stat.rating ?? 0.0),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Center(
                  child: Text(
                    (stat.rating ?? 0.0).toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // (Widget _teamRow)
  Widget _teamRow(BuildContext context, String flagUrl, String name) {
    return Row(
      children: [
        Image.asset(
          flagUrl,
          width: 20,
          height: 15,
          fit: BoxFit.cover,
          errorBuilder: (c, e, s) => const Icon(Icons.flag, size: 15),
        ),
        const SizedBox(width: 8),
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