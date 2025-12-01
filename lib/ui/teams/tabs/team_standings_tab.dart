import 'package:flutter/material.dart';
import 'package:myfdb/data/model/models.dart';
import 'package:myfdb/ui/teams/team_detail_page.dart';
import 'package:myfdb/ui/teams/team_detail_viewmodel.dart';

class TeamStandingsTab extends StatefulWidget {
  final String group; // Tab này cần biết đang ở Bảng A hay B
  final int currentTeamId; // Để tô màu đội hiện tại
  final TeamDetailViewModel viewModel; // Dùng chung ViewModel

  const TeamStandingsTab({
    super.key,
    required this.group,
    required this.currentTeamId,
    required this.viewModel,
  });

  @override
  State<TeamStandingsTab> createState() => _TeamStandingsTabState();
}

class _TeamStandingsTabState extends State<TeamStandingsTab> with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    // Yêu cầu ViewModel tải BXH cho Bảng này
    widget.viewModel.loadStandings(widget.group);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<List<TeamStanding>>(
      stream: widget.viewModel.standingsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Không có dữ liệu bảng xếp hạng.'));
        }

        final standings = snapshot.data!;

        // Dùng SingleChildScrollView để bảng có thể cuộn ngang
        return SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: Card( // Bọc trong Card cho đẹp
            elevation: 2.0,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // Cho phép cuộn ngang
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 60,
                columnSpacing: 18, // Tăng khoảng cách cột
                columns: const [
                  DataColumn(label: Text('VT', style: TextStyle(fontWeight: FontWeight.bold))), // Vị trí
                  DataColumn(label: Text('Đội', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('ST', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('T', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('H', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('B', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('HS', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Đ', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                // Tạo hàng (row) từ danh sách
                rows: List.generate(standings.length, (index) {
                  final s = standings[index]; // Lấy 1 đội
                  final pos = index + 1; // Vị trí (1, 2, 3...)

                  final isCurrentTeam = (s.team.id == widget.currentTeamId);
                  final rowColor = isCurrentTeam
                      ? MaterialStateProperty.all(Colors.blue.shade50) // Màu xanh nhạt
                      : null; // Mặc định

                  return DataRow(
                    color: rowColor, // Áp dụng màu
                    cells: [
                      DataCell(Text(pos.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(
                        InkWell(
                          onTap: () {
                            if (isCurrentTeam) return; // Không cần bấm vào chính mình
                            Navigator.pushReplacement( // Thay thế trang
                              context,
                              MaterialPageRoute(
                                builder: (context) => TeamDetailPage(team: s.team),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Image.asset(
                                s.team.flagUrl,
                                width: 24,
                                height: 18,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(Icons.flag, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Text(s.team.code), // Dùng code (VIE, THA) cho ngắn
                            ],
                          ),
                        ),
                      ),
                      DataCell(Text(s.mp.toString())),
                      DataCell(Text(s.w.toString())),
                      DataCell(Text(s.d.toString())),
                      DataCell(Text(s.l.toString())),
                      DataCell(Text(s.gd.toString())),
                      DataCell(Text(s.pts.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}