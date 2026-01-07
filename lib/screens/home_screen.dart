import 'package:flutter/material.dart';
import 'garden_screen.dart';
import 'gacha_screen.dart';
import 'lottery_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    GardenScreen(),   // 育成画面
    GachaScreen(),    // ガチャ
    ExchangeScreen(), // 交換
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 199, 255, 234),
      body: _pages[_selectedIndex],  // 選択されたページを表示

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
          _selectedIndex = index;
          });
        },


        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_florist),
            label: "育成",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: "ガチャ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: "交換",
          ),
        ],
      ),
    );
  }
}
