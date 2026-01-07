import 'package:flutter/material.dart';
import '../../logic/gacha_logic.dart';

// ★ ガチャの結果を表示するためのデータクラスを作ります
class GachaResultData {
  final GachaRarity rarity;
  final String title;
  final IconData icon;
  final Color color;
  final Color textColor;

  GachaResultData({
    required this.rarity,
    required this.title,
    required this.icon,
    required this.color,
    this.textColor = Colors.black87,
  });
}

class GachaResultCard extends StatelessWidget {
  // ★ Rarity単体ではなく、詳細データを受け取るように変更
  final GachaResultData data;

  const GachaResultCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // ★ ベースのカード
    final card = Card(
      color: data.color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: data.rarity == GachaRarity.high 
            ? const BorderSide(color: Colors.white, width: 2) // 高レアは白枠付き
            : BorderSide.none,
      ),
      elevation: data.rarity == GachaRarity.high ? 8 : 3,
      child: SizedBox(
        width: 100, // 少し幅を広げました
        height: 130,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ★ アイコンを表示
            Icon(data.icon, size: 32, color: data.textColor.withOpacity(0.7)),
            const SizedBox(height: 8),
            // ★ 具体的な名前を表示（「バレンタインの木」など）
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13, // 文字数が増えるので少し小さめに
                color: data.textColor,
              ),
            ),
          ],
        ),
      ),
    );

    // ★ 高レアだけ、ボヨンと大きく強調表示
    if (data.rarity == GachaRarity.high) {
      return Transform.scale(
        scale: 1.15,
        child: card,
      );
    }

    return card;
  }
}