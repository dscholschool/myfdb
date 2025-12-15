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
      // Nếu đã đá: Tải đội hình & thống kê
      _viewModel.loadLineups(widget.match.homeTeamId, widget.match.awayTeamId);
      _viewModel.loadDetails(widget.match.matchId);
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
        StreamBuilder<Map<String, List<Player>>>(
          stream: _viewModel.lineupStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) return _buildLineupSection(context, snapshot.data!);
            return const SizedBox.shrink();
          },
        ),
        const Divider(thickness: 1, height: 1),
        StreamBuilder<MatchDetail>(
          stream: _viewModel.detailsStream,
          builder: (context, snapshot) {
            if (snapshot.hasData) return _buildStatsSection(context, snapshot.data!);
            return const SizedBox(height: 50, child: Center(child: CircularProgressIndicator()));
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

  Widget _buildLineupSection(BuildContext context, Map<String, List<Player>> lineups) {
    final homePlayers = lineups['home'] ?? [];
    final awayPlayers = lineups['away'] ?? [];
    final homeTeamName = widget.match.homeTeam?.name ?? "Home Team";
    final awayTeamName = widget.match.awayTeam?.name ?? "Away Team";

    if (homePlayers.isEmpty && awayPlayers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text("Chưa có thông tin đội hình")),
      );
    }

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
          const SizedBox(height: 4),
          const SizedBox(height: 16),

          TacticalBoard(
            homePlayers: homePlayers,
            awayPlayers: awayPlayers,
            homeTeamName: homeTeamName,
            awayTeamName: awayTeamName,
            homeFlagUrl: widget.match.homeTeam?.flagUrl,
            awayFlagUrl: widget.match.awayTeam?.flagUrl,

            // === THÊM PHẦN NÀY ĐỂ CHUYỂN TRANG ===
            onPlayerTap: (player) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerDetailPage(player: player),
                ),
              );
            },
          ),
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

// === WIDGET SÂN BÓNG MỚI ===
class TacticalBoard extends StatelessWidget {
  final List<Player> homePlayers;
  final List<Player> awayPlayers;
  final String homeTeamName;
  final String awayTeamName;
  final String? homeFlagUrl;
  final String? awayFlagUrl;
  // Thêm callback để xử lý khi nhấn vào cầu thủ
  final Function(Player) onPlayerTap;

  const TacticalBoard({
    super.key,
    required this.homePlayers,
    required this.awayPlayers,
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeFlagUrl,
    this.awayFlagUrl,
    required this.onPlayerTap, // Bắt buộc truyền vào
  });

  @override
  Widget build(BuildContext context) {
    // Phân loại cầu thủ (Giữ nguyên)
    final hGK = homePlayers.where((p) => p.position.contains('Thủ môn') || p.position.contains('GK')).toList();
    final hDF = homePlayers.where((p) => p.position.contains('Hậu vệ') || p.position.contains('DF')).toList();
    final hMF = homePlayers.where((p) => p.position.contains('Tiền vệ') || p.position.contains('MF')).toList();
    final hFW = homePlayers.where((p) => p.position.contains('Tiền đạo') || p.position.contains('FW')).toList();

    final aGK = awayPlayers.where((p) => p.position.contains('Thủ môn') || p.position.contains('GK')).toList();
    final aDF = awayPlayers.where((p) => p.position.contains('Hậu vệ') || p.position.contains('DF')).toList();
    final aMF = awayPlayers.where((p) => p.position.contains('Tiền vệ') || p.position.contains('MF')).toList();
    final aFW = awayPlayers.where((p) => p.position.contains('Tiền đạo') || p.position.contains('FW')).toList();

    return Container(
      height: 640,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF12D870), // Màu cỏ xanh dịu
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // LỚP 1: VẼ SÂN (Giữ nguyên)
          Center(child: Container(height: 2, color: Colors.white.withOpacity(0.4))),
          Center(
            child: Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 50, left: 80, right: 80, height: 80,
            child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white.withOpacity(0.4), width: 2))),
          ),
          Positioned(
            bottom: 50, left: 80, right: 80, height: 80,
            child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.white.withOpacity(0.4), width: 2))),
          ),

          // LỚP 2: BỐ TRÍ CẦU THỦ
          Column(
            children: [
              const SizedBox(height: 50),
              // ĐỘI NHÀ
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLine(hGK),
                    _buildLine(hDF),
                    _buildLine(hMF),
                    _buildLine(hFW),
                  ],
                ),
              ),
              // KHOẢNG CÁCH GIỮA 2 ĐỘI
              const SizedBox(height: 40),
              // ĐỘI KHÁCH
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildLine(aFW),
                    _buildLine(aMF),
                    _buildLine(aDF),
                    _buildLine(aGK),
                  ],
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),

          // LỚP 3: HEADER & FOOTER (Giữ nguyên)
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.white.withOpacity(0.9),
              child: Row(
                children: [
                  Image.asset(homeFlagUrl!, width: 24),
                  const SizedBox(width: 8),
                  Text(homeTeamName.toUpperCase(), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.white.withOpacity(0.9),
              child: Row(
                children: [
                  Image.asset(awayFlagUrl!, width: 24),
                  const SizedBox(width: 8),
                  Text(awayTeamName.toUpperCase(), style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14)),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(List<Player> linePlayers) {
    if (linePlayers.isEmpty) return const SizedBox(height: 30);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: linePlayers.map((player) => _buildPlayerIcon(player)).toList(),
    );
  }

  Widget _buildPlayerIcon(Player player) {
    String displayName = player.name;
    if (player.name.contains(' ')) {
      displayName = player.name.split(' ').last;
    }

    // === THÊM GESTURE DETECTOR ĐỂ BẮT SỰ KIỆN NHẤN ===
    return GestureDetector(
      onTap: () => onPlayerTap(player), // Gọi callback khi nhấn
      behavior: HitTestBehavior.opaque, // Giúp bắt sự kiện chính xác hơn
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: player.imageUrl.isNotEmpty
                  ? AssetImage(player.imageUrl)
                  : null,
              child: player.imageUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "${player.jerseyNumber}",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  shadows: const [Shadow(blurRadius: 2, color: Colors.black)],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  shadows: [Shadow(blurRadius: 3, color: Colors.black)],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}