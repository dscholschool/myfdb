import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myfdb/data/model/models.dart';
import 'package:myfdb/ui/home/home_viewmodel.dart';
import 'package:myfdb/ui/match_detail/match_detail_page.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Match> _finishedMatches = [];
  List<Match> _scheduledMatches = [];
  late HomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
    _viewModel.loadMatches();
    observeData();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  // === SỬA LỖI SẮP XẾP Ở ĐÂY ===
  void observeData() {
    // 1. Lắng nghe các trận ĐÃ DIỄN RA
    _viewModel.finishedMatches.listen((matches) {
      // Sắp xếp: Mới nhất -> Cũ nhất
      matches.sort((a, b) => b.date.compareTo(a.date));
      setState(() {
        _finishedMatches = matches;
      });
    });

    // 2. Lắng nghe các trận SẮP DIỄN RA
    _viewModel.scheduledMatches.listen((matches) {
      // Sắp xếp: Cũ nhất -> Mới nhất (để trận nào đá trước hiện trước)
      matches.sort((a, b) => a.date.compareTo(b.date));
      setState(() {
        _scheduledMatches = matches;
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
    bool showLoading = _finishedMatches.isEmpty && _scheduledMatches.isEmpty;
    if (showLoading) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          // Mục "Sắp diễn ra" vẫn ở trên cùng
          _buildMatchSection(
            title: 'Các trận đấu sắp diễn ra',
            matches: _scheduledMatches,
          ),
          // Mục "Đã diễn ra" ở dưới, nhưng đã được sắp xếp lại
          _buildMatchSection(
            title: 'Các trận đấu đã diễn ra',
            matches: _finishedMatches,
          ),
        ],
      );
    }
  }

  Widget _buildMatchSection({required String title, required List<Match> matches}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 20.0, 16.0, 12.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (matches.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Không có trận đấu nào.'),
          ),

        Column(
          children: matches.map((match) => _MatchCard(match: match)).toList(),
        ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final Match match;
  const _MatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('HH:mm dd/MM');

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchDetailPage(match: match),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        color: Colors.white,
        elevation: 2.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 12.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _TeamInfo(team: match.homeTeam)),
                  _ScoreColumn(score: match.score, status: match.status),
                  Expanded(child: _TeamInfo(team: match.awayTeam)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                formatter.format(match.date.toLocal()),
                style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w500),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamInfo extends StatelessWidget {
  final Team? team;
  final CrossAxisAlignment align; // Thêm align
  const _TeamInfo({this.team, this.align = CrossAxisAlignment.center});

  @override
  Widget build(BuildContext context) {
    if (team == null) return const Expanded(child: Text('...'));

    return Column(
      crossAxisAlignment: align,
      children: [
        Image.asset(
          team!.flagUrl,
          width: 50,
          height: 35,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.flag, size: 35, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        Text(
          team!.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}


class _ScoreColumn extends StatelessWidget {
  final Score? score;
  final String status;
  const _ScoreColumn({this.score, required this.status});

  @override
  Widget build(BuildContext context) {
    String scoreText;
    if (status == 'SCHEDULED') {
      scoreText = 'vs';
    } else if (score != null) {
      scoreText = '${score!.home} - ${score!.away}';
    } else {
      scoreText = '? - ?';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        scoreText,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}