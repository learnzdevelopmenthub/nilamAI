import 'package:flutter/material.dart';

import '../core/constants/strings_tamil.dart';
import 'crops/crops_list_screen.dart';
import 'diagnose/diagnose_screen.dart';
import 'home/home_screen.dart';
import 'market/market_screen.dart';
import 'schemes/schemes_screen.dart';

/// Top-level shell for the 5-tab navigation. Each tab is a full screen with
/// its own AppBar; this scaffold only owns the bottom NavigationBar so tab
/// transitions feel instant (the IndexedStack keeps state alive per tab).
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _index = 0;

  static const _tabs = <Widget>[
    HomeScreen(),
    CropsListScreen(),
    DiagnoseScreen(),
    MarketScreen(),
    SchemesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: TamilStrings.navHome,
          ),
          NavigationDestination(
            icon: Icon(Icons.agriculture_outlined),
            selectedIcon: Icon(Icons.agriculture),
            label: TamilStrings.navCrops,
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services),
            label: TamilStrings.navDiagnose,
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            selectedIcon: Icon(Icons.show_chart),
            label: TamilStrings.navMarket,
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: TamilStrings.navSchemes,
          ),
        ],
      ),
    );
  }
}
