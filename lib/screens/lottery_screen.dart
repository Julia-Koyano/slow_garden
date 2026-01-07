import 'package:flutter/material.dart';
import '../managers/garden_save_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../managers/my_banner_ad.dart'; 

// ★ ギフトのデータ型（画像パスを追加しました）
class GiftItem {
  final String id;        // Firebase検索用ID
  final String title;     // 商品名
  final String shopName;  // お店の名前
  final String expiry;    // 有効期限
  final int cost;         // 必要ポイント
  final String imagePath; // 画像の場所

  GiftItem({
    required this.id,
    required this.title,
    required this.shopName,
    required this.expiry,
    required this.cost,
    required this.imagePath,
  });
}

class ExchangeScreen extends StatefulWidget {
  const ExchangeScreen({super.key});

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  final save = GardenSaveManager.instance;

  // ★ 1. ここに実際のギフトデータを登録してください
  final List<GiftItem> giftList = [
    GiftItem(
      id: 'famima_500', // Firebaseの 'type' と合わせる
      title: '500円お買い物券',
      shopName: 'ファミリーマート',
      expiry: '有効期限：1ヶ月後の月末',
      cost: 50000,
      imagePath: 'assets/images/gift_famima.png', 
    ),
    GiftItem(
      id: 'lawson_100', 
      title: 'お買物券 (100円)',
      shopName: 'LAWSON (ローソン)',
      expiry: '有効期限：1ヶ月後の月末',
      cost: 10000,
      imagePath: 'assets/images/gift_lawson.png',
    ),
    GiftItem(
      id: 'misterdonut_200',
      title: 'ギフトチケット (200円)',
      shopName: 'ミスタードーナツ',
      expiry: '有効期限：6ヶ月',
      cost: 20000,
      imagePath: 'assets/images/gift_donut.png',
    ),
    // 必要ならもっと追加できます
  ];

  // ★ 交換処理（Firebaseロジックはそのまま活用！）
  void runExchange(GiftItem item) async {
    // 1. ポイント不足チェック
    if (save.point < item.cost) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text("ポイント不足"),
          content: Text("ポイントが足りません。"),
        ),
      );
      return;
    }

    // 2. 確認ダイアログ
    final bool? confirm = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item.title),
        content: Text("${item.cost}ポイントを消費して\n交換しますか？"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("やめる"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("交換する"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 3. Firebaseから在庫を探す
    try {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final snapshot = await FirebaseFirestore.instance
          .collection('gifts')
          .where('isUsed', isEqualTo: false)
          .where('type', isEqualTo: item.id) // IDで検索
          .limit(1)
          .get();

      if (!mounted) return;
      Navigator.pop(context);

      // A. 在庫切れ
      if (snapshot.docs.isEmpty) {
        showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text("在庫切れ"),
            content: Text("申し訳ありません。\n現在チケットの在庫がありません。"),
          ),
        );
        return;
      }

      // B. 在庫あり
      final doc = snapshot.docs.first;
      final url = doc['url'] as String;

      // セーブ処理
      setState(() {
        save.point -= item.cost;
        // ギフト履歴に追加（※もし履歴機能があれば）
        // save.addGiftHistory(url); 
        save.save();
      });

      // Firebase更新
      await doc.reference.update({'isUsed': true});

      // URLを開く
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'URLが開けませんでした';
      }

    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("エラー"),
          content: Text("エラーが発生しました: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0), // 背景グレー
      appBar: AppBar(
        title: const Text("交換", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      bottomNavigationBar: const SafeArea(child: MyBannerAd()),
      
      body: Column(
        children: [
          // ポイント表示エリア
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.savings, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  "現在のポイント: ${save.point} pt",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // リスト表示エリア
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: giftList.length,
              itemBuilder: (context, index) {
                final item = giftList[index];
                final canExchange = save.point >= item.cost;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  color: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // 上段：画像とテキスト
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ■ 画像エリア
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  item.imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, o, s) => const Icon(Icons.card_giftcard, size: 40, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // ■ テキストエリア
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.shopName,
                                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.expiry,
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 下段：交換ボタン
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            icon: Icon(
                              Icons.diamond_outlined,
                              size: 18,
                              color: canExchange ? Colors.white : Colors.grey,
                            ),
                            label: Text(
                              "${item.cost} で交換",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: canExchange ? Colors.white : Colors.grey,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canExchange ? Colors.green : Colors.grey.shade300,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            // 足りないときは押せない
                            onPressed: canExchange ? () => runExchange(item) : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFF0F0F0),
            width: double.infinity,
            child: const Text(
              "※本アプリにおけるキャンペーン・プレゼントは本アプリ運営者が独自に行うものであり、米Apple inc.及びApple Japan合同会社とは一切関係ありません。",
              style: TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}