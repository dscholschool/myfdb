import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:myfdb/ui/home/home.dart';
import 'package:myfdb/ui/players/players.dart';
import 'package:myfdb/ui/table/table.dart';
import 'package:myfdb/ui/teams/teams.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyFDB - AFF Cup Demo',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.red,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F4F8),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MainAppShell(),
    );
  }
}

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  final List<Widget> _tabs = [
    const HomeTab(),
    const TableTab(),
    const TeamsTab(),
    const PlayersTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text(
          'MyFDB - AFF Cup Demo',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red,
      ),
      child: CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          backgroundColor: Colors.red,
          activeColor: Colors.yellow,
          inactiveColor: Colors.yellow.withOpacity(0.7),
          items: const [
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.home), label: 'Trang chủ'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.table), label: 'BXH'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.flag), label: 'Đội tuyển'),
            BottomNavigationBarItem(icon: Icon(CupertinoIcons.person_3), label: 'Cầu thủ'),
          ],
        ),
        tabBuilder: (BuildContext context, int index) {
          return _tabs[index];
        },
      ),
    );
  }
}