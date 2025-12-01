import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myfdb/data/model/models.dart';
import 'package:myfdb/ui/players/players_viewmodel.dart';
import 'package:myfdb/ui/players/player_detail_page.dart';

class PlayersTab extends StatelessWidget {
  const PlayersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlayersPage(); // Trả về trang có logic
  }
}

class PlayersPage extends StatefulWidget {
  const PlayersPage({super.key});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
  List<Player> _players = [];
  late PlayersViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PlayersViewModel();
    _viewModel.loadPlayers(); // Bắt đầu tải
    observeData(); // Bắt đầu lắng nghe
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  // Lắng nghe stream
  void observeData() {
    _viewModel.playersStream.listen((playerList) {
      setState(() {
        _players = playerList;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: getBody(),
    );
  }

  Widget getBody() {
    bool showLoading = _players.isEmpty;
    if (showLoading) {
      return getProgressBar();
    } else {
      return GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 cột
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: (1 / 1.4),
        ),
        itemCount: _players.length,
        itemBuilder: (context, index) {
          return _PlayerGridItem(player: _players[index]);
        },
      );
    }
  }

  Widget getProgressBar() {
    return const Center(child: CircularProgressIndicator());
  }
}

class _PlayerGridItem extends StatelessWidget {
  final Player player;
  const _PlayerGridItem({required this.player});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
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
        clipBehavior: Clip.antiAlias,
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
                  const SizedBox(height: 6),
                  // Đội tuyển (dùng "JOIN" data)
                  Row(
                    children: [
                      Image.asset(
                        player.team?.flagUrl ?? 'assets/images/default_flag.png',
                        width: 20,
                        height: 14,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(Icons.flag, size: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        player.team?.name ?? 'Không rõ',
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}