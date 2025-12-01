import 'package:flutter/material.dart';
import 'package:myfdb/data/model/models.dart';
import 'package:myfdb/ui/teams/team_detail_viewmodel.dart';
import 'package:myfdb/ui/teams/tabs/team_matches_tab.dart';
import 'package:myfdb/ui/teams/tabs/team_players_tab.dart';
import 'package:myfdb/ui/teams/tabs/team_standings_tab.dart';
import 'tabs/team_stats_tab.dart';

class TeamDetailPage extends StatefulWidget {
  final Team team;
  const TeamDetailPage({super.key, required this.team});

  @override
  State<TeamDetailPage> createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends State<TeamDetailPage> {
  late TeamDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TeamDetailViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thông tin đội tuyển'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: Column(
          children: [
            // 1. Header
            _buildTeamHeader(context, widget.team),

            // 2. Thanh Tab
            const Material(
              color: Colors.white,
              elevation: 1,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: Colors.red,
                unselectedLabelColor: Colors.black54,
                indicatorColor: Colors.red,
                tabs: [
                  Tab(text: 'TRẬN ĐẤU'),
                  Tab(text: 'BẢNG XẾP HẠNG'),
                  Tab(text: 'CẦU THỦ'),
                  Tab(text: 'THỐNG KÊ'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Trận đấu
                  TeamMatchesTab(
                    teamId: widget.team.id,
                    viewModel: _viewModel,
                  ),

                  // Tab 2: Bảng Xếp Hạng
                  TeamStandingsTab(
                    group: widget.team.group, // Truyền Bảng (A/B)
                    currentTeamId: widget.team.id, // Truyền ID đội (để tô màu)
                    viewModel: _viewModel,
                  ),

                  // Tab 3: Cầu thủ
                  TeamPlayersTab(
                    teamId: widget.team.id,
                    viewModel: _viewModel,
                  ),

              // Tab 4: Thống kê
              TeamStatsTab(teamId: widget.team.id, viewModel: _viewModel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamHeader(BuildContext context, Team team) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            team.flagUrl,
            width: 100,
            height: 70,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => const Icon(Icons.flag, size: 70),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderInfoRow(label: 'Tên đội tuyển', value: team.name),
                _HeaderInfoRow(label: 'Mã FIFA', value: team.code),
                _HeaderInfoRow(label: 'Sân nhà', value: team.homeStadium),
                _HeaderInfoRow(label: 'Sức chứa', value: team.capacity.toString()),
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