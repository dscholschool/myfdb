import 'package:flutter/material.dart';
import 'package:myfdb/data/model/models.dart';
import 'package:myfdb/ui/players/player_detail_viewmodel.dart';
import 'package:myfdb/ui/players/tabs/player_matches_tab.dart';
import 'tabs/player_stats_tab.dart';

class PlayerDetailPage extends StatefulWidget {
  final Player player;
  const PlayerDetailPage({super.key, required this.player});

  @override
  State<PlayerDetailPage> createState() => _PlayerDetailPageState();
}

class _PlayerDetailPageState extends State<PlayerDetailPage> {
  late PlayerDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = PlayerDetailViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thông tin cầu thủ'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: Column(
          children: [
            // 1. Header
            _buildPlayerHeader(context, widget.player),

            // 2. Thanh Tab
            const Material(
              color: Colors.white,
              elevation: 1,
              child: TabBar(
                isScrollable: false,
                tabAlignment: TabAlignment.fill,
                labelColor: Colors.red,
                unselectedLabelColor: Colors.black54,
                indicatorColor: Colors.red,
                tabs: [
                  Tab(text: 'TRẬN ĐẤU'),
                  Tab(text: 'THỐNG KÊ'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1
                  PlayerMatchesTab(
                    player: widget.player,
                    viewModel: _viewModel, // Dùng chung ViewModel
                  ),

                  // Tab 2: Thống kê
                  PlayerStatsTab(player: widget.player, viewModel: _viewModel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerHeader(BuildContext context, Player player) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bên trái: Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: AssetImage(player.imageUrl),
            // Bắt lỗi nếu file ảnh chưa có
            onBackgroundImageError: (e, s) {
              const AssetImage('assets/images/players/default_avatar.png');
            },
          ),
          const SizedBox(width: 16),
          // Bên phải: Thông tin (Kiểu Key-Value)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderInfoRow(label: 'Tên cầu thủ', value: player.name),
                // Dùng "team" đã được "join" từ Repository
                _HeaderInfoRow(label: 'Quốc tịch', value: player.team?.name ?? 'N/A'),
                _HeaderInfoRow(label: 'Vị trí', value: player.position),
                _HeaderInfoRow(label: 'Số áo', value: player.jerseyNumber.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderInfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _HeaderInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Colors.black54),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            TextSpan(text: value),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}