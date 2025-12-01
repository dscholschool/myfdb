import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:myfdb/data/model/models.dart';
import 'package:myfdb/data/repository/repository.dart';
import 'package:myfdb/ui/teams/team_detail_viewmodel.dart';

class TeamStatsTab extends StatefulWidget {
  final int teamId;
  final TeamDetailViewModel viewModel;

  const TeamStatsTab({super.key, required this.teamId, required this.viewModel});

  @override
  State<TeamStatsTab> createState() => _TeamStatsTabState();
}

class _TeamStatsTabState extends State<TeamStatsTab> with AutomaticKeepAliveClientMixin {
  final _repository = DefaultRepository();

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadMatches(widget.teamId);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StreamBuilder<List<Match>>(
            stream: widget.viewModel.matchesStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox(height: 100, child: Center(child: Text('Đang tải...')));
              final matches = snapshot.data!.where((m) => m.status == 'FINISHED').toList();
              matches.sort((a, b) => a.date.compareTo(b.date));
              if (matches.isEmpty) return const Center(child: Text('Chưa có trận đấu nào kết thúc.'));
              return Column(children: [_buildFormBarChart(matches), const SizedBox(height: 24), _buildGoalsBarChart(matches)]);
            },
          ),

          const SizedBox(height: 32),

          StreamBuilder<TeamChartData>(
            stream: widget.viewModel.chartDataStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
              final data = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Tổng quan Sức mạnh (DNA)"),
                  const SizedBox(height: 16),
                  _buildRadarChartSection(data), // Widget Radar đã được nâng cấp

                  const SizedBox(height: 32),
                  _buildSectionTitle("Kiểm soát bóng"),
                  const SizedBox(height: 16),
                  _buildPossessionPieChartSection(data),
                ],
              );
            },
          ),

          const SizedBox(height: 32),
          _buildSectionTitle("Hiệu suất Tấn công"),
          const SizedBox(height: 16),
          _buildAttackBarChartSection(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  // === WIDGET RADAR CHART ===
  Widget _buildRadarChartSection(TeamChartData data) {
    return Card(
      elevation: 4, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 300,
          child: RadarChart(
            RadarChartData(
              radarTouchData: RadarTouchData(enabled: false),
              dataSets: [
                RadarDataSet(
                  fillColor: Colors.red.withOpacity(0.4), borderColor: Colors.red, entryRadius: 3,
                  // Dùng biến SCORE để vẽ hình
                  dataEntries: [
                    RadarEntry(value: data.avgGoals),
                    RadarEntry(value: data.avgShotsOnTarget),
                    RadarEntry(value: data.avgPossession),
                    RadarEntry(value: data.avgPassAccuracy),
                    RadarEntry(value: data.defenseScore),
                    RadarEntry(value: data.disciplineScore),
                  ],
                ),
              ],
              radarBackgroundColor: Colors.transparent, borderData: FlBorderData(show: false),
              radarBorderData: const BorderSide(color: Colors.grey, width: 1),
              titlePositionPercentageOffset: 0.15,
              titleTextStyle: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.bold),

              // === HIỂN THỊ TEXT KÈM SỐ LIỆU THỰC TẾ ===
              getTitle: (index, angle) {
                switch (index) {
                  case 0: return RadarChartTitle(text: 'Ghi bàn');
                  case 1: return RadarChartTitle(text: 'Sút trúng');
                  case 2: return RadarChartTitle(text: 'Kiểm soát');
                  case 3: return RadarChartTitle(text: 'Chuyền bóng');
                  case 4: return RadarChartTitle(text: 'Phòng ngự');
                  case 5: return RadarChartTitle(text: 'Fair Play');
                  default: return const RadarChartTitle(text: '');
                }
              },
              tickCount: 4, ticksTextStyle: const TextStyle(color: Colors.transparent),
              tickBorderData: const BorderSide(color: Colors.grey, width: 0.5), gridBorderData: const BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
        ),
      ),
    );
  }

  // === WIDGET PIE POSSESSION ===
  Widget _buildPossessionPieChartSection(TeamChartData data) {
    return Card(
      elevation: 4, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(children: [
          SizedBox(width: 120, height: 120, child: PieChart(PieChartData(sectionsSpace: 0, centerSpaceRadius: 30, sections: [PieChartSectionData(color: Colors.red, value: data.overallPossession, title: '${data.overallPossession.toStringAsFixed(0)}%', radius: 30, titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)), PieChartSectionData(color: Colors.grey.shade200, value: 100 - data.overallPossession, title: '', radius: 25)]))),
          const SizedBox(width: 24),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Trung bình kiểm soát", style: TextStyle(color: Colors.grey)), Text("${data.overallPossession.toStringAsFixed(1)}%", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red)), const SizedBox(height: 8), _buildStatRow("Chuyền chính xác", "${data.avgPassAccuracy.toStringAsFixed(1)}%")]))
        ]),
      ),
    );
  }

  Widget _buildFormBarChart(List<Match> matches) {
    return Card(elevation: 2, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(16.0), child: Column(children: [const Text("Phong độ gần đây", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 8), const Text("(Hiệu số bàn thắng & Đối thủ)", style: TextStyle(fontSize: 12, color: Colors.grey)), const SizedBox(height: 24), SizedBox(height: 220, child: BarChart(BarChartData(alignment: BarChartAlignment.spaceAround, maxY: 6, minY: -6, gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) { if (value == 0) return const FlLine(color: Colors.black26, strokeWidth: 1); return const FlLine(color: Colors.transparent); }), titlesData: FlTitlesData(leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) { int index = value.toInt(); if (index >= 0 && index < matches.length) { var m = matches[index]; bool isHome = m.homeTeamId == widget.teamId; Team? opponent = isHome ? m.awayTeam : m.homeTeam; if (opponent != null) { return Column(mainAxisAlignment: MainAxisAlignment.end, children: [Image.asset(opponent.flagUrl, width: 24, height: 16, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.flag, size: 16)), const SizedBox(height: 2), const Text("vs", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold))]); } } return const SizedBox.shrink(); }))), borderData: FlBorderData(show: false), barGroups: List.generate(matches.length, (index) { var m = matches[index]; bool isHome = m.homeTeamId == widget.teamId; int gf = isHome ? m.score!.home : m.score!.away; int ga = isHome ? m.score!.away : m.score!.home; double gd = (gf - ga).toDouble(); Color color; if (gd > 0) color = Colors.green; else if (gd < 0) color = Colors.red; else color = Colors.grey; double yVal = gd; if (gd == 0) yVal = 0.3; return BarChartGroupData(x: index, barRods: [BarChartRodData(toY: yVal, color: color, width: 16, borderRadius: BorderRadius.circular(2))]); })))), const SizedBox(height: 16), const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_ChartLegend(color: Colors.green, text: "Thắng"), _ChartLegend(color: Colors.grey, text: "Hòa"), _ChartLegend(color: Colors.red, text: "Thua")])])));
  }

  Widget _buildGoalsBarChart(List<Match> matches) {
    return Card(elevation: 2, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(16.0), child: Column(children: [const Text("Bàn thắng vs. Bàn thua", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 24), SizedBox(height: 200, child: BarChart(BarChartData(gridData: const FlGridData(show: false), titlesData: FlTitlesData(leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 1)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) => (val.toInt() >= 0 && val.toInt() < matches.length) ? Padding(padding: const EdgeInsets.only(top: 8), child: Text("M${val.toInt()+1}", style: const TextStyle(fontSize: 10))) : const SizedBox.shrink()))), borderData: FlBorderData(show: true, border: const Border(bottom: BorderSide(color: Colors.grey), left: BorderSide(color: Colors.grey))), barGroups: List.generate(matches.length, (i) { var m = matches[i]; bool isHome = m.homeTeamId == widget.teamId; return BarChartGroupData(x: i, barRods: [BarChartRodData(toY: (isHome ? m.score!.home : m.score!.away).toDouble(), color: Colors.blue, width: 12), BarChartRodData(toY: (isHome ? m.score!.away : m.score!.home).toDouble(), color: Colors.redAccent, width: 12)]); })))), const SizedBox(height: 16), const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_ChartLegend(color: Colors.blue, text: "Bàn thắng"), _ChartLegend(color: Colors.redAccent, text: "Bàn thua")])])));
  }

  Widget _buildAttackBarChartSection() {
    return StreamBuilder<List<Match>>(
      stream: widget.viewModel.matchesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final matches = snapshot.data!.where((m) => m.status == 'FINISHED').toList();
        matches.sort((a, b) => a.date.compareTo(b.date));

        return FutureBuilder<List<MatchDetail>>(
          future: Future.wait(matches.map((m) => _repository.getMatchDetails(m.matchId).then((d) => d!))),
          builder: (context, detailSnapshot) {
            if (!detailSnapshot.hasData) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
            final details = detailSnapshot.data!;
            double totalShotsAll = 0; double totalOnTargetAll = 0;
            for (int i = 0; i < matches.length; i++) { bool isHome = matches[i].homeTeamId == widget.teamId; totalShotsAll += (isHome ? details[i].shots.home : details[i].shots.away).toDouble(); totalOnTargetAll += (isHome ? details[i].shotsOnTarget.home : details[i].shotsOnTarget.away).toDouble(); }
            double avgAccuracy = totalShotsAll > 0 ? (totalOnTargetAll / totalShotsAll * 100) : 0;

            return Card(elevation: 4, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.all(16.0), child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Biểu đồ dứt điểm", style: TextStyle(color: Colors.grey, fontSize: 14)), RichText(text: TextSpan(style: const TextStyle(fontSize: 14, color: Colors.black87), children: [const TextSpan(text: "Độ chính xác: "), TextSpan(text: "${avgAccuracy.toStringAsFixed(1)}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))]))]), const SizedBox(height: 24), SizedBox(height: 220, child: BarChart(BarChartData(alignment: BarChartAlignment.spaceAround, titlesData: FlTitlesData(leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 5)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (val, meta) => Text('M${val.toInt()+1}', style: const TextStyle(fontSize: 10, color: Colors.grey))))), borderData: FlBorderData(show: true, border: const Border(bottom: BorderSide(color: Colors.grey), left: BorderSide(color: Colors.grey))), gridData: const FlGridData(show: true, drawVerticalLine: false), barGroups: List.generate(matches.length, (i) { bool isHome = matches[i].homeTeamId == widget.teamId; double goals = (isHome ? matches[i].score!.home : matches[i].score!.away).toDouble(); double onTarget = (isHome ? details[i].shotsOnTarget.home : details[i].shotsOnTarget.away).toDouble(); double total = (isHome ? details[i].shots.home : details[i].shots.away).toDouble(); return BarChartGroupData(x: i, barRods: [BarChartRodData(toY: total, width: 18, borderRadius: BorderRadius.circular(2), rodStackItems: [BarChartRodStackItem(0, goals, Colors.green), BarChartRodStackItem(goals, onTarget, Colors.blue), BarChartRodStackItem(onTarget, total, Colors.grey.shade300)])]); })))), const SizedBox(height: 16), const Row(mainAxisAlignment: MainAxisAlignment.center, children: [_ChartLegend(color: Colors.green, text: "Bàn thắng"), SizedBox(width: 12), _ChartLegend(color: Colors.blue, text: "Bị cản phá"), SizedBox(width: 12), _ChartLegend(color: Colors.grey, text: "Sút trượt")])])));
          },
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(fontSize: 14, color: Colors.black87)), Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))]);
  }

  @override
  bool get wantKeepAlive => true;
}

class _ChartLegend extends StatelessWidget {
  final Color color; final String text;
  const _ChartLegend({required this.color, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 4), Text(text, style: const TextStyle(fontSize: 12, color: Colors.black87))]);
  }
}