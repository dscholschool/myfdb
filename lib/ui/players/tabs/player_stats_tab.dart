import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:myfdb/data/model/models.dart';
import 'package:myfdb/ui/players/player_detail_viewmodel.dart';

class PlayerStatsTab extends StatefulWidget {
  final Player player;
  final PlayerDetailViewModel viewModel;

  const PlayerStatsTab({
    super.key,
    required this.player,
    required this.viewModel,
  });

  @override
  State<PlayerStatsTab> createState() => _PlayerStatsTabState();
}

class _PlayerStatsTabState extends State<PlayerStatsTab>
    with AutomaticKeepAliveClientMixin {
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
        // 1. Đang tải
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Có lỗi
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }

        // 3. Dữ liệu rỗng -> Hiện thông báo cập nhật
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

        // 4. Có dữ liệu -> Tính toán và vẽ
        final stats = snapshot.data!;
        stats.sort((a, b) {
          if (a.match == null || b.match == null) return 0;
          return a.match!.date.compareTo(b.match!.date);
        });

        final avgRating = _calculateAvgRating(stats);
        final chartData = _calculateChartData(stats, widget.player);
        final aggregatedData = _calculateAggregatedStats(stats, widget.player);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. BIỂU ĐỒ RADAR
              _buildSectionTitle("Chỉ số tổng thể"),
              const SizedBox(height: 16),
              _buildRadarChart(chartData),

              const SizedBox(height: 32),

              // 2. BIỂU ĐỒ PHONG ĐỘ
              _buildSectionTitle("Phong độ thi đấu"),
              const SizedBox(height: 16),
              _buildRatingChartSection(stats, avgRating),

              const SizedBox(height: 32),

              // 3. SỐ LIỆU CHI TIẾT
              _buildSectionTitle("Thống kê chi tiết"),
              const SizedBox(height: 16),
              _buildDetailedStatsSection(aggregatedData),
            ],
          ),
        );
      },
    );
  }

  // === LOGIC TÍNH TOÁN ===
  double _calculateAvgRating(List<PlayerStat> stats) {
    if (stats.isEmpty) return 0.0;
    double total = stats.fold(0.0, (sum, item) => sum + (item.rating ?? 0.0));
    return total / stats.length;
  }

  PlayerChartData _calculateChartData(List<PlayerStat> stats, Player player) {
    int count = stats.length;
    double totalGoals = 0, totalShots = 0, totalAssists = 0, totalKeyPasses = 0, totalProgressive = 0;
    double totalTackles = 0,
        totalDefense = 0,
        totalPassAcc = 0,
        totalErrors = 0,
        totalSaves = 0;

    for (var s in stats) {
      totalGoals += s.goal;
      totalShots += s.shotsOnTarget;
      totalAssists += s.assists;
      totalKeyPasses += s.keyPasses;
      totalProgressive += s.progressive;
      totalTackles += s.successfulTackles;
      totalDefense += s.defenseAction;
      totalPassAcc += s.passAccuracy;
      totalErrors += s.errors;
      totalSaves += s.saves;
    }

    double avgGoals = totalGoals / count;
    double attackScore = (avgGoals * 40 + (totalShots / count) * 10).clamp(
      0,
      100,
    );
    double creativityScore =
        ((totalAssists / count) * 40 + (totalKeyPasses / count) * 20).clamp(
          0,
          100,
        );
    double defenseScore =
        ((totalTackles / count) * 20 + (totalDefense / count) * 10).clamp(
          0,
          100,
        );
    double technicalScore = (totalPassAcc / count).clamp(0, 100);
    double tacticalScore = (100 - (totalErrors / count * 20)).clamp(0, 100);

    if (player.position == 'Thủ môn') {
      defenseScore = ((totalSaves / count) * 20).clamp(0, 100);
      attackScore = 10;
    }

    // Bây giờ class PlayerChartData đã có đủ các trường này
    return PlayerChartData(
      attackScore: attackScore,
      defenseScore: defenseScore,
      creativityScore: creativityScore,
      technicalScore: technicalScore,
      tacticalScore: tacticalScore,
      goals: totalGoals.toInt(),
      assists: totalAssists.toInt(),
      shots: totalShots.toInt(),
      totalPasses: 0,
      passAccuracy: totalPassAcc / count,
    );
  }

  AggregatedPlayerStats _calculateAggregatedStats(
    List<PlayerStat> stats,
    Player player,
  ) {
    int tGoals = 0, tAssists = 0, tShots = 0, tKey = 0, tMiss = 0, tPro = 0;
    double tPassAcc = 0;
    int tDef = 0, tTack = 0, tAir = 0, tErr = 0, tSav = 0, tCon = 0, tClean = 0;

    for (var s in stats) {
      tGoals += s.goal;
      tAssists += s.assists;
      tShots += s.shotsOnTarget;
      tKey += s.keyPasses;
      tPro += s.progressive;
      tMiss += s.missChances;
      tPassAcc += s.passAccuracy;
      tDef += s.defenseAction;
      tTack += s.successfulTackles;
      tAir += s.aerialDueWon;
      tErr += s.errors;
      tSav += s.saves;
      tCon += s.goalsConceded;

      if (s.match != null) {
        bool isHome = s.match!.homeTeamId == widget.player.teamId;
        int ga = isHome ? s.match!.score!.away : s.match!.score!.home;
        if (ga == 0) tClean++;
      }
    }

    return AggregatedPlayerStats(
      matchesPlayed: stats.length,
      totalGoals: tGoals,
      totalAssists: tAssists,
      totalShotsOnTarget: tShots,
      totalKeyPasses: tKey,
      totalProgressive: tPro,
      totalMissChances: tMiss,
      avgPassAccuracy: tPassAcc / stats.length,
      totalDefenseActions: tDef,
      totalSuccessfulTackles: tTack,
      totalAerialDuelsWon: tAir,
      totalErrors: tErr,
      totalSaves: tSav,
      totalGoalsConceded: tCon,
      cleanSheets: tClean,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildRadarChart(PlayerChartData data) {
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 250,
          child: RadarChart(
            RadarChartData(
              dataSets: [
                RadarDataSet(
                  fillColor: Colors.blue.withOpacity(0.3),
                  borderColor: Colors.blue,
                  entryRadius: 2,
                  dataEntries: [
                    RadarEntry(value: data.attackScore),
                    RadarEntry(value: data.creativityScore),
                    RadarEntry(value: data.technicalScore),
                    RadarEntry(value: data.tacticalScore),
                    RadarEntry(value: data.defenseScore),
                  ],
                ),
              ],
              radarBackgroundColor: Colors.transparent,
              borderData: FlBorderData(show: false),
              radarBorderData: const BorderSide(color: Colors.grey, width: 0.5),
              titlePositionPercentageOffset: 0.1,
              titleTextStyle: const TextStyle(
                color: Colors.black87,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              getTitle: (index, angle) {
                switch (index) {
                  case 0:
                    return const RadarChartTitle(text: 'Tấn công');
                  case 1:
                    return const RadarChartTitle(text: 'Sáng tạo');
                  case 2:
                    return const RadarChartTitle(text: 'Kỹ thuật');
                  case 3:
                    return const RadarChartTitle(text: 'Fair play');
                  case 4:
                    return const RadarChartTitle(text: 'Phòng ngự');
                  default:
                    return const RadarChartTitle(text: '');
                }
              },
              tickCount: 4,
              ticksTextStyle: const TextStyle(color: Colors.transparent),
              tickBorderData: const BorderSide(color: Colors.grey, width: 0.5),
              gridBorderData: const BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingChartSection(List<PlayerStat> stats, double avgRating) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Phong độ cầu thủ",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      if (value == 0 || value == 5 || value == 10)
                        return const FlLine(color: Colors.transparent);
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 30,
                        getTitlesWidget: (val, meta) => Text(
                          val.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (val, meta) => Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            val.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: 10,
                  showingTooltipIndicators: stats
                      .asMap()
                      .entries
                      .map(
                        (e) => ShowingTooltipIndicators([
                          LineBarSpot(
                            _createLineBarData(stats),
                            0,
                            FlSpot(e.key.toDouble() + 1, e.value.rating ?? 0.0),
                          ),
                        ]),
                      )
                      .toList(),
                  lineTouchData: LineTouchData(
                    enabled: false,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (spot) => Colors.transparent,
                      tooltipPadding: EdgeInsets.zero,
                      tooltipMargin: 8,
                      getTooltipItems: (spots) => spots
                          .map(
                            (s) => LineTooltipItem(
                              s.y.toStringAsFixed(1),
                              const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  lineBarsData: [_createLineBarData(stats)],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Rating trung bình: ",
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getRatingColor(avgRating),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      avgRating.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  LineChartBarData _createLineBarData(List<PlayerStat> stats) {
    return LineChartBarData(
      spots: List.generate(
        stats.length,
        (i) => FlSpot(i.toDouble() + 1, stats[i].rating ?? 0.0),
      ),
      isCurved: true,
      color: Colors.green,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: Colors.greenAccent.withOpacity(0.1),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 8.0) return Colors.blue;
    if (rating >= 7.0) return Colors.green;
    if (rating >= 6.0) return Colors.orange;
    return Colors.red;
  }

  Widget _buildDetailedStatsSection(AggregatedPlayerStats data) {
    final passAcc = data.avgPassAccuracy.toStringAsFixed(1);
    List<Widget> defenseRows = [];
    if (widget.player.position == 'Thủ môn') {
      defenseRows = [
        _buildStatRow("Giữ sạch lưới", data.cleanSheets.toString()),
        _buildStatRow("Cứu thua", data.totalSaves.toString()),
        _buildStatRow("Bàn thua", data.totalGoalsConceded.toString()),
      ];
    } else {
      defenseRows = [
        _buildStatRow(
          "Hành động phòng ngự",
          data.totalDefenseActions.toString(),
        ),
        _buildStatRow(
          "Tắc bóng thành công",
          data.totalSuccessfulTackles.toString(),
        ),
        _buildStatRow(
          "Không chiến thành công",
          data.totalAerialDuelsWon.toString(),
        ),
        _buildStatRow("Phạm lỗi", data.totalErrors.toString()),
        if (widget.player.position == 'Hậu vệ')
          _buildStatRow("Giữ sạch lưới", data.cleanSheets.toString()),
      ];
    }
    return Column(
      children: [
        _buildStatCard("Tấn công", [
          _buildStatRow("Số trận đã đá", data.matchesPlayed.toString()),
          _buildStatRow("Bàn thắng", data.totalGoals.toString()),
          _buildStatRow("Kiến tạo", data.totalAssists.toString()),
          _buildStatRow("Sút trúng đích", data.totalShotsOnTarget.toString()),
          _buildStatRow("Cơ hội bị bỏ lỡ", data.totalMissChances.toString()),
        ]),
        const SizedBox(height: 16),
        _buildStatCard("Chuyền bóng & Kiến thiết", [
          _buildStatRow(
            "Đường chuyền quyết định",
            data.totalKeyPasses.toString(),
          ),
          _buildStatRow("Tỷ lệ chuyền chính xác (TB)", "$passAcc%"),
          _buildStatRow(
            "Kéo bóng",
            data.totalProgressive.toString(),
          ),
        ]),
        const SizedBox(height: 16),
        _buildStatCard("Phòng thủ", defenseRows),
      ],
    );
  }

  Widget _buildStatCard(String title, List<Widget> rows) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // === SỬA LỖI QUAN TRỌNG: THÊM HÀM NÀY ===
  @override
  bool get wantKeepAlive => true;
}
