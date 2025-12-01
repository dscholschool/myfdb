import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myfdb/data/model/models.dart';
import 'package:myfdb/ui/teams/teams_viewmodel.dart';
import 'package:myfdb/ui/teams/team_detail_page.dart';

class TeamsTab extends StatelessWidget {
  const TeamsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const TeamsPage();
  }
}

class TeamsPage extends StatefulWidget {
  const TeamsPage({super.key});

  @override
  State<TeamsPage> createState() => _TeamsPageState();
}

class _TeamsPageState extends State<TeamsPage> {
  List<Team> _teams = [];
  late TeamsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TeamsViewModel();
    _viewModel.loadTeams(); // Bắt đầu tải
    observeData(); // Bắt đầu lắng nghe
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  // Lắng nghe stream
  void observeData() {
    _viewModel.teamsStream.listen((teamList) {
      setState(() {
        _teams.addAll(teamList);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold sẽ tự động có nền trắng/xám nhạt
    return Scaffold(
      body: getBody(),
    );
  }

  Widget getBody() {
    bool showLoading = _teams.isEmpty;
    if (showLoading) {
      return getProgressBar();
    } else {
      return getListView();
    }
  }

  Widget getProgressBar() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget getListView() {
    // Dùng ListView.separated để có vạch kẻ
    return ListView.separated(
      itemBuilder: (context, position) {
        return getRow(_teams[position]);
      },
      separatorBuilder: (context, index) {
        return const Divider(
          color: Colors.grey,
          thickness: 0.5,
          indent: 16,
          endIndent: 16,
        );
      },
      itemCount: _teams.length,
    );
  }

  // Widget để vẽ 1 hàng
  Widget getRow(Team team) {
    return Card(
      elevation: 0, // Không cần bóng
      margin: EdgeInsets.zero,
      color: Colors.white, // Đảm bảo nền trắng
      child: ListTile(
        leading: Image.asset(
          team.flagUrl,
          width: 48,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.flag, size: 32, color: Colors.grey);
          },
        ),
        title: Text(
          team.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(
          CupertinoIcons.chevron_forward,
          color: Colors.grey,
          size: 18,
        ),
        onTap: () {
          // Điều hướng sang trang chi tiết
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TeamDetailPage(team: team),
            ),
          );
        },
      ),
    );
  }
}