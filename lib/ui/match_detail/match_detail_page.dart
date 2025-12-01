import 'package:flutter/material.dart';
import 'package:myfdb/data/model/models.dart';
import 'package:myfdb/ui/match_detail/match_detail_viewmodel.dart';
import 'package:myfdb/ui/players/player_detail_page.dart';
import 'package:myfdb/ui/teams/team_detail_page.dart';

class MatchDetailPage extends StatefulWidget {
  final Match match;
  const MatchDetailPage({super.key, required this.match});

  @override
  State<MatchDetailPage> createState() => _MatchDetailPageState();
}

class _MatchDetailPageState extends State<MatchDetailPage> {
  late MatchDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MatchDetailViewModel();

    // === LOGIC CHIA LUỒNG ===
    if (widget.match.status == 'FINISHED') {
      // Nếu đã đá: Tải thống kê & đội hình
      _viewModel.loadDetails(widget.match.matchId);
      _viewModel.loadLineups(widget.match.homeTeamId, widget.match.awayTeamId);
    } else {
      // Nếu sắp đá: Tải dự đoán DA
      _viewModel.loadPrediction(widget.match);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            title: Text(
              widget.match.group == 'SF' ? 'Bán kết' : 'Vòng bảng',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            pinned: true,
            floating: true,
            snap: true,
            elevation: 2.0,
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildScoreboard(context, widget.match),
              const Divider(thickness: 1, height: 1),

              // === HIỂN THỊ NỘI DUNG THEO TRẠNG THÁI ===
              if (widget.match.status == 'FINISHED')
                _buildFinishedMatchContent()
              else
                _buildPredictionContent(),

              _buildVenueSection(context, widget.match.homeTeam),
            ]),
          ),
        ],
      ),
    );
  }

  // === 1. NỘI DUNG CHO TRẬN ĐÃ ĐÁ (Thống kê + Đội hình) ===
  Widget _buildFinishedMatchContent() {
    return Column(
      children: [
        StreamBuilder<MatchDetail>(
          stream: _viewModel.detailsStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) return _buildStatsSection(context, snapshot.data!);
            return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
          },
        ),
        const Divider(thickness: 1, height: 1),
        StreamBuilder<Map<String, List<Player>>>(
          stream: _viewModel.lineupStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) return _buildLineupSection(context, snapshot.data!);
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  // === 2. NỘI DUNG CHO TRẬN SẮP ĐÁ (Dự đoán DA) ===
  Widget _buildPredictionContent() {
    return StreamBuilder<MatchPrediction>(
      stream: _viewModel.predictionStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: Text('Chưa có dữ liệu dự đoán')),
          );
        }

        final prediction = snapshot.data!;

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Center(
                child: Text(
                  'PHÂN TÍCH DỰ ĐOÁN TRẬN ĐẤU',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '(Dựa trên Poisson & Rule-based Model)',
                style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),

              Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _PredictionRow(
                        label: 'Dự đoán Tỷ số',
                        value: prediction.scorePrediction,
                        isHighlight: true,
                      ),
                      const Divider(),
                      _PredictionRow(
                        label: 'Kèo Handicap',
                        value: prediction.handicapPick,
                      ),
                      _PredictionRow(
                        label: 'Kèo O/U Bàn thắng',
                        value: prediction.goalOverUnderLine,
                      ),
                      _PredictionRow(
                        label: 'Kèo O/U Thẻ phạt',
                        value: prediction.cardOverUnderLine,
                      ),
                      // === THÊM HIỂN THỊ GÓC ===
                      const Divider(),
                      _PredictionRow(
                        label: 'Kèo Handicap Góc',
                        value: prediction.cornerHandicapPick,
                      ),
                      _PredictionRow(
                        label: 'Kèo O/U Phạt góc',
                        value: prediction.cornerOverUnderLine,
                      ),
                      const SizedBox(height: 12),
                      // === WIDGET THANH XÁC SUẤT (Probability Bar) ===
                      const Text("XÁC SUẤT THẮNG", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 10),
                      _ProbabilityBar(
                        homeName: widget.match.homeTeam?.name ?? "Home",
                        awayName: widget.match.awayTeam?.name ?? "Away",
                        win: prediction.winProbability,
                        draw: prediction.drawProbability,
                        lose: prediction.loseProbability,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScoreboard(BuildContext context, Match match) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Row(
        children: [
          Expanded(child: _TeamInfo(team: match.homeTeam, align: CrossAxisAlignment.center)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              match.score != null ? '${match.score!.home} - ${match.score!.away}' : 'vs',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          Expanded(child: _TeamInfo(team: match.awayTeam, align: CrossAxisAlignment.center)),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context, MatchDetail details) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              'Thống kê trận đấu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2.0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _StatRow(label: 'Kiểm soát bóng', homeValue: details.possession.home, awayValue: details.possession.away, isPercent: true),
                  _StatRow(label: 'Số lần sút', homeValue: details.shots.home, awayValue: details.shots.away),
                  _StatRow(label: 'Sút trúng đích', homeValue: details.shotsOnTarget.home, awayValue: details.shotsOnTarget.away),
                  _StatRow(label: 'Lượt chuyền bóng', homeValue: details.passes.home, awayValue: details.passes.away),
                  _StatRow(label: 'Tỷ lệ chuyền chính xác', homeValue: details.passAccuracy.home, awayValue: details.passAccuracy.away, isPercent: true),
                  _StatRow(label: 'Phạm lỗi', homeValue: details.fouls.home, awayValue: details.fouls.away),
                  _StatRow(label: 'Thẻ vàng', homeValue: details.yellowCards.home, awayValue: details.yellowCards.away),
                  _StatRow(label: 'Thẻ đỏ', homeValue: details.redCards.home, awayValue: details.redCards.away),
                  _StatRow(label: 'Việt vị', homeValue: details.offsides.home, awayValue: details.offsides.away),
                  _StatRow(label: 'Phạt góc', homeValue: details.corners.home, awayValue: details.corners.away),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineupSection(BuildContext context, Map<String, List<Player>> lineups) {
    final homePlayers = lineups['home'] ?? [];
    final awayPlayers = lineups['away'] ?? [];
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Center(
            child: Text(
              'Đội hình ra sân',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: homePlayers.map((player) {
                    return InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerDetailPage(player: player)));
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text('${player.jerseyNumber} - ${player.name}', style: const TextStyle(fontSize: 14, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: awayPlayers.map((player) {
                    return InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerDetailPage(player: player)));
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text('${player.name} - ${player.jerseyNumber}', textAlign: TextAlign.end, style: const TextStyle(fontSize: 14, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildVenueSection(BuildContext context, Team? homeTeam) {
    if (homeTeam == null || homeTeam.homeStadium.isEmpty) return const SizedBox.shrink();
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const Icon(Icons.location_on_outlined, color: Colors.grey, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(homeTeam.homeStadium, style: TextStyle(color: Colors.grey[700], fontSize: 14))),
        ],
      ),
    );
  }
}

class _PredictionRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  const _PredictionRow({required this.label, required this.value, this.isHighlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15, color: Colors.black54)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isHighlight ? Colors.red : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: isHighlight ? 18 : 14,
                fontWeight: FontWeight.bold,
                color: isHighlight ? Colors.white : Colors.red.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// === WIDGET THANH XÁC SUẤT ===
class _ProbabilityBar extends StatelessWidget {
  final String homeName;
  final String awayName;
  final double win;
  final double draw;
  final double lose;

  const _ProbabilityBar({
    required this.homeName,
    required this.awayName,
    required this.win,
    required this.draw,
    required this.lose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Nhãn: Tên đội và %
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                "$homeName\n${win.toStringAsFixed(0)}%",
                style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center
            ),
            Text(
                "Hòa\n${draw.toStringAsFixed(0)}%",
                style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center
            ),
            Text(
                "$awayName\n${lose.toStringAsFixed(0)}%",
                style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Thanh Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                Expanded(flex: win.toInt(), child: Container(color: Colors.redAccent)),
                Expanded(flex: draw.toInt(), child: Container(color: Colors.grey.shade300)),
                Expanded(flex: lose.toInt(), child: Container(color: Colors.blueAccent)),
              ],
            ),
          ),
        )
      ],
    );
  }
}

class _TeamInfo extends StatelessWidget {
  final Team? team;
  final CrossAxisAlignment align;
  const _TeamInfo({this.team, this.align = CrossAxisAlignment.center});
  @override
  Widget build(BuildContext context) {
    if (team == null) return const Column(children: [CircularProgressIndicator()]);

    return GestureDetector(
      onTap: () {
        // Điều hướng sang trang chi tiết
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeamDetailPage(team: team!),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: align,
        children: [
          Image.asset(
            team!.flagUrl,
            width: 60,
            height: 42,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.flag, size: 42, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Text(
            team!.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int homeValue;
  final int awayValue;
  final bool isPercent;
  const _StatRow({required this.label, required this.homeValue, required this.awayValue, this.isPercent = false});
  @override
  Widget build(BuildContext context) {
    final String homeText = isPercent ? '$homeValue%' : '$homeValue';
    final String awayText = isPercent ? '$awayValue%' : '$awayValue';
    bool homeWins = homeValue > awayValue;
    bool awayWins = awayValue > homeValue;
    if (label.contains('Phạm lỗi') || label.contains('Thẻ') || label.contains('Việt vị')) {
      homeWins = homeValue < awayValue;
      awayWins = awayValue < homeValue;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatBubble(text: homeText, isHighlighted: homeWins, color: Colors.red),
          Expanded(child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w500))),
          _StatBubble(text: awayText, isHighlighted: awayWins, color: Colors.blue),
        ],
      ),
    );
  }
}

class _StatBubble extends StatelessWidget {
  final String text;
  final bool isHighlighted;
  final Color color;
  const _StatBubble({required this.text, required this.isHighlighted, required this.color});
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withOpacity(0.9) : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isHighlighted ? Colors.white : Colors.black87)),
    );
  }
}