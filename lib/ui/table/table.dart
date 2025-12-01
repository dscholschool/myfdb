import 'package:flutter/material.dart';
import 'package:myfdb/data/model/models.dart';
import 'package:myfdb/ui/table/table_viewmodel.dart';
import 'package:myfdb/ui/teams/team_detail_page.dart';

class TableTab extends StatelessWidget {
  const TableTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const TablePage();
  }
}

// Đây là UI chính
class TablePage extends StatefulWidget {
  const TablePage({super.key});

  @override
  State<TablePage> createState() => _TablePageState();
}

class _TablePageState extends State<TablePage> {
  late TableViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = TableViewModel();
    _viewModel.loadStandings(); // Bắt đầu tải
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dùng StreamBuilder để lắng nghe ViewModel
      body: StreamBuilder<Map<String, List<TeamStanding>>>(
        stream: _viewModel.standings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có dữ liệu bảng xếp hạng.'));
          }

          // Lấy 2 bảng đã được sắp xếp
          final groupA = snapshot.data!['A']!;
          final groupB = snapshot.data!['B']!;

          // Hiển thị 2 bảng trong ListView
          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              _buildGroupTable(context, 'Bảng A', groupA),
              const SizedBox(height: 20),
              _buildGroupTable(context, 'Bảng B', groupB),
            ],
          );
        },
      ),
    );
  }

  // Widget để vẽ 1 bảng xếp hạng (Bảng A hoặc B)
  Widget _buildGroupTable(BuildContext context, String title, List<TeamStanding> standings) {
    return Card(
      elevation: 2.0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            // Dùng DataTable cho giao diện bảng chuyên nghiệp
            // Phải bọc trong SingleChildScrollView để không lỗi overflow
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 36,
                dataRowMinHeight: 48,
                dataRowMaxHeight: 60,
                columnSpacing: 16,
                // Định nghĩa các cột
                columns: const [
                  DataColumn(label: Text('Đội', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('ST', style: TextStyle(fontWeight: FontWeight.bold))), // Số trận
                  DataColumn(label: Text('T', style: TextStyle(fontWeight: FontWeight.bold))),  // Thắng
                  DataColumn(label: Text('H', style: TextStyle(fontWeight: FontWeight.bold))),  // Hòa
                  DataColumn(label: Text('B', style: TextStyle(fontWeight: FontWeight.bold))),  // Bại
                  DataColumn(label: Text('HS', style: TextStyle(fontWeight: FontWeight.bold))), // Hiệu số
                  DataColumn(label: Text('Đ', style: TextStyle(fontWeight: FontWeight.bold))),  // Điểm
                ],
                // Đổ dữ liệu vào các hàng
                rows: standings.map((s) {
                  return DataRow(cells: [
                    // Tên đội (có cờ)
                    DataCell(
                      Row(
                        children: [
                          Image.asset(
                            s.team.flagUrl,
                            width: 30,
                            height: 20,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const Icon(Icons.flag, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(s.team.code), // Dùng code (VIE, THA) cho ngắn
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TeamDetailPage(team: s.team),
                          ),
                        );
                      },
                    ),
                    DataCell(Text(s.mp.toString())),
                    DataCell(Text(s.w.toString())),
                    DataCell(Text(s.d.toString())),
                    DataCell(Text(s.l.toString())),
                    DataCell(Text(s.gd.toString())),
                    DataCell(Text(s.pts.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}