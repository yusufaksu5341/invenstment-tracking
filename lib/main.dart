import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:investment_tracking/add.dart';
import 'package:investment_tracking/graph.dart';
import 'package:investment_tracking/settings.dart';
import 'package:investment_tracking/notifications.dart';
import 'package:investment_tracking/wallet.dart';
void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}


 class _MainAppState extends State<MainApp> {
  int selectedIndex = 0;

final List<Widget> pages = [
  WalletPage(yatirimlar: globalYatirimlar),
  const Graph(coinSymbol: 'BTC', interval: '1y'),
  const Add(),
  const Notifications(),
  const Settings(),
];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        bottomNavigationBar: CurvedNavigationBar(
          backgroundColor: const Color.fromARGB(255, 9, 11, 16),
          items: const <Widget>[
            Icon(Icons.account_balance_wallet_sharp, size: 30),
            Icon(Icons.insert_chart, size: 30),
            Icon(Icons.add, size: 30),
            Icon(Icons.notifications, size: 30),
            Icon(Icons.settings, size: 30),
          ],
          onTap: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
        ),
        body: pages[selectedIndex], 
      ),
    );
  }
}