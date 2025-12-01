import 'package:flutter/material.dart';
import 'package:myfdb/data/model/models.dart';
import 'package:myfdb/ui/teams/team_detail_viewmodel.dart';
import 'package:myfdb/ui/players/player_detail_page.dart';

class TeamPlayersTab extends StatefulWidget {
  final int teamId; // Tab này cần biết nó đang hiển thị cho đội nào
  final TeamDetailViewModel viewModel; // Dùng chung ViewModel

  const TeamPlayersTab({
    super.key,
    required this.teamId,
    required this.viewModel,
  });

  @override
  State<TeamPlayersTab> createState() => _TeamPlayersTabState();
}

class _TeamPlayersTabState extends State<TeamPlayersTab> with AutomaticKeepAliveClientMixin {

  @override
  void initState() {
    super.initState();
    // Yêu cầu ViewModel tải dữ liệu
    widget.viewModel.loadPlayers(widget.teamId);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Bắt buộc để giữ state

    return StreamBuilder<List<Player>>(
      stream: widget.viewModel.playersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Không có dữ liệu cầu thủ.'));
        }

        final players = snapshot.data!;

        // === DÙNG GRIDVIEW Y HỆT TAB "CẦU THỦ" CHÍNH ===
        return GridView.builder(
          padding: const EdgeInsets.all(8.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 cột
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
            childAspectRatio: (1 / 1.4), // Tỷ lệ (rộng / cao)
          ),
          itemCount: players.length,
          itemBuilder: (context, index) {
            // Dùng widget _PlayerGridItem (được định nghĩa bên dưới)
            return _PlayerGridItem(player: players[index]);
          },
        );
      },
    );
  }

  // Giữ cho tab "sống" (không bị tải lại)
  @override
  bool get wantKeepAlive => true;
}

// === WIDGET CON ĐỂ VẼ 1 Ô CẦU THỦ (Tương tự file players.dart) ===
class _PlayerGridItem extends StatelessWidget {
  final Player player;
  const _PlayerGridItem({required this.player});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Bấm vào sẽ điều hướng đến trang Chi tiết Cầu thủ
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerDetailPage(player: player),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Card(
        elevation: 2.0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        clipBehavior: Clip.antiAlias, // Để bo tròn cả ảnh
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. ẢNH CẦU THỦ
            Expanded(
              child: Image.asset(
                player.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/players/default_avatar.png',
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            // 2. PHẦN THÔNG TIN
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên cầu thủ
                  Text(
                    player.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Vị trí
                  Text(
                    player.position,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  // (Không cần hiển thị cờ/tên đội vì đã ở trong trang đội đó rồi)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}