import 'package:flutter/material.dart';
import 'package:myfdb/data/model/models.dart';

class PlayerMatchStatsPage extends StatelessWidget {
  final Player player;
  final PlayerStat stat;

  const PlayerMatchStatsPage({
    super.key,
    required this.player,
    required this.stat,
  });

  @override
  Widget build(BuildContext context) {
    final match = stat.match; // Trận đấu đã được join

    return Scaffold(
      appBar: AppBar(
        title: Text(player.name),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header (Hiển thị Tên, Rating, và Đối thủ)
            _buildHeader(context),
            const Divider(height: 1),

            // 2. Danh sách Thống kê (Giống ảnh Diogo Costa)
            _buildStatList(context),
          ],
        ),
      ),
    );
  }

  // Header (Tên, Rating, Trận đấu)
  Widget _buildHeader(BuildContext context) {
    if (stat.match == null) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage(player.imageUrl),
            onBackgroundImageError: (e,s) => const AssetImage('assets/images/players/default_avatar.png'),
          ),
          const SizedBox(width: 12),
          // Tên, Trận đấu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  player.position,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
          // Rating
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _getRatingColor(stat.rating ?? 0.0),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              (stat.rating ?? 0.0).toStringAsFixed(1),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          )
        ],
      ),
    );
  }

  // Danh sách thống kê
  Widget _buildStatList(BuildContext context) {
    // Chỉ hiển thị các thống kê có ý nghĩa cho vị trí này
    List<Widget> statsWidgets = [];

    if (player.position == 'Thủ môn') {
      statsWidgets = [
        _StatRow(label: 'Cứu bóng', value: stat.saves.toString()),
        _StatRow(label: 'Tỉ lệ cản phá', value: '${stat.savePercent}%'),
        _StatRow(label: 'Cản phá Penalty', value: stat.penaltySave.toString()),
        _StatRow(label: 'Bàn thua', value: stat.goalsConceded.toString()),
      ];
    } else {
      statsWidgets = [
        _StatRow(label: 'Bàn thắng', value: stat.goal.toString()),
        _StatRow(label: 'Kiến tạo', value: stat.assists.toString()),
        _StatRow(label: 'Sút trúng đích', value: stat.shotsOnTarget.toString()),
        _StatRow(label: 'Bỏ lỡ cơ hội', value: stat.missChances.toString()),
        _StatRow(label: 'Key Passes', value: stat.keyPasses.toString()),
        _StatRow(label: 'Chuyền chính xác', value: '${stat.passAccuracy}%'),
        _StatRow(label: 'Kéo bóng (Progressive)', value: stat.progressive.toString()),
      ];
    }

    // Thêm các stats chung
    statsWidgets.addAll([
      _StatRow(label: 'Đoạt bóng (Defense Action)', value: stat.defenseAction.toString()),
      _StatRow(label: 'Tắc bóng thành công', value: stat.successfulTackles.toString()),
      _StatRow(label: 'Thắng không chiến', value: stat.aerialDueWon.toString()),
      _StatRow(label: 'Mất bóng (1/3 sân nhà)', value: stat.lostPossessionOnFinalThird.toString()),
      _StatRow(label: 'Mất bóng (ngoài 1/3 sân nhà)', value: stat.lostPossessionOutsideFinalThird.toString()),
      _StatRow(label: 'Phạm lỗi', value: stat.errors.toString()),
    ]);

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(children: statsWidgets),
    );
  }

  // Widget 1 hàng (giống Diogo Costa)
  Widget _StatRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: Colors.black54)),
          Text(value, style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // (Copy logic màu từ file kia)
  Color _getRatingColor(double rating) {
    if (rating >= 8.0) return Colors.blue.shade400;
    if (rating >= 7.0) return Colors.green.shade400;
    if (rating >= 6.0) return Colors.orange.shade400;
    return Colors.red.shade400;
  }
}