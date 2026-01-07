import 'package:flutter/material.dart';

class GachaInfoBoard extends StatelessWidget {
  const GachaInfoBoard({super.key});

  @override
  Widget build(BuildContext context) {
    // 期間判定
    final now = DateTime.now();
    final eventEnd = DateTime(2026, 3, 31, 23, 59); 
    final isEventActive = now.isBefore(eventEnd);

    return Card(
      // 角を丸くする設定（画像の角も一緒に丸くするため）
      clipBehavior: Clip.antiAlias, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      
      // イベント中は背景ピンク、普段は水色
      color: isEventActive 
          ? const Color.fromARGB(255, 255, 240, 245) // 少し薄めのピンクにしました
          : const Color.fromARGB(255, 215, 255, 254),
      
      margin: const EdgeInsets.all(12),
      child: Column(
        children: [
          // ★★★ ここに画像を追加！ ★★★
          if (isEventActive)
            Image.asset(
              'assets/images/valentine/banner_valentine.png', // 作った画像を指定
              width: double.infinity, // 横幅いっぱいに広げる
              fit: BoxFit.cover,      // 隙間なく埋める
            ),

          // 今までのテキスト説明部分は Padding で包んで下に配置
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 画像がある時は、タイトル（バレンタインガチャ開催中！）は消してもいいかも？
                // 必要なら残しておいてOKです
                if (!isEventActive) ...[
                  Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        "ガチャの説明",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // 詳細テキスト（ここは画像の下に残しておくと親切です）
                const Text("🎯 単発：ガチャの実 10個 / 10連：100個"),
                const SizedBox(height: 4),
                const Text(
                  "✨ 10連は中レア以上1個確定！",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
                
                const Divider(), 

                // 🌱 低レア
                const Text("🌱 低レア:", style: TextStyle(fontWeight: FontWeight.bold)),
                const Padding(
                  padding: EdgeInsets.only(left: 10, bottom: 8),
                  child: Text("1 ポイント / ガチャの実 10個"),
                ),

                // 🌿 中レア
                const Text("🌿 中レア:", style: TextStyle(fontWeight: FontWeight.bold)),
                const Padding(
                  padding: EdgeInsets.only(left: 10, bottom: 8),
                  child: Text("500 Pt / 🧪肥料 / 🚿ジョウロ / ガチャの実 100個"),
                ),

                // 🌳 高レア
                const Text("🌳 高レア:", style: TextStyle(fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: isEventActive 
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // 左揃えにする（お好みで）
                      children: [
                         // ▼ 1行目：バレンタイン
                         Row(
                           children: const [
                              Icon(Icons.favorite, color: Colors.red, size: 20),
                              SizedBox(width: 4),
                              Text(
                              "【期間限定】バレンタインの木",
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              ),
                           ],
    ),
    
    // 行と行の間を少し空けると読みやすいです
    const SizedBox(height: 8), 

    // ▼ 2行目：ホワイトデー
    Row(
      children: const [
        Icon(Icons.favorite, color: Color.fromARGB(255, 54, 216, 244), size: 20),
        SizedBox(width: 4),
        Text(
          "【期間限定】ホワイトデーの木",
          style: TextStyle(
            color: Color.fromARGB(255, 54, 216, 244),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    ),
  ],
)
                    : const Text("はじまりの木 / 10,000 Pt"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}