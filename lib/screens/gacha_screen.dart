import 'package:flutter/material.dart';
import '../managers/garden_save_manager.dart';
import '../logic/gacha_logic.dart';
import 'widgets/gacha_info_board.dart';
import 'widgets/gacha_result_card.dart';
import '../managers/my_banner_ad.dart'; 
import '../managers/my_reward_ad.dart';

// ★★★ 1. シェア用ライブラリをインポート ★★★
import 'package:share_plus/share_plus.dart';

class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key});

  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> {
  final save = GardenSaveManager.instance;
  List<GachaResultData> results = [];
  final MyRewardAd _rewardAdHelper = MyRewardAd();

  @override
  void initState() {
    super.initState();
    _rewardAdHelper.load();
  }

  @override
  void dispose() {
    _rewardAdHelper.dispose();
    super.dispose();
  }

  void rollSingle() {
    if (save.gachaCount < 10) return;
    _rewardAdHelper.show(
      context: context,
      onReward: () {
        setState(() { save.gachaCount -= 10; });
        final r = drawNormal();
        _applyResult([r]);
      },
    );
    
    // 強制的に「最高レア」を引いたことにする！
    /*
    final r = GachaRarity.high; 
    _applyResult([r]);
    */
  }

  void rollTen() {
    if (save.gachaCount < 100) return;
    _rewardAdHelper.show(
      context: context,
      onReward: () {
        setState(() { save.gachaCount -= 100; });
        final List<GachaRarity> list = [];
        for (int i = 0; i < 9; i++) { list.add(drawNormal()); }
        list.add(drawGuaranteed());
        _applyResult(list);
      },
    );
  }

  void _applyResult(List<GachaRarity> list) async {
    List<GachaResultData> displayList = [];
    int addPoints = 0;
    int addGachaFruits = 0;
    int addExp = 0;
    bool hasWateringCan = false;
    String gotTreeName = ""; // ★ これに値が入っていれば高レア！

    final now = DateTime.now();
    final eventEnd = DateTime(2026, 3, 31, 23, 59);
    final isEventActive = now.isBefore(eventEnd);

    for (final r in list) {
      switch (r) {
        case GachaRarity.low:
          if (random.nextInt(2) == 0) { 
            addPoints += 1; 
            displayList.add(GachaResultData(
              rarity: r, title: "1 pt", icon: Icons.star, color: Colors.grey.shade200
            ));
            } else { 
              addGachaFruits += 10; 
              displayList.add(GachaResultData(
              rarity: r, title: "実 x10", icon: Icons.casino, color: Colors.orange.shade100
            ));
              }
          break;

        case GachaRarity.mid:
          int type = random.nextInt(4);
          if (type == 0) { 
            addExp += 500; 
            displayList.add(GachaResultData(
              rarity: r, title: "経験値\n+500", icon: Icons.science, color: Colors.blue.shade100
            ));
            } 
          else if (type == 1) { 
            hasWateringCan = true; 
            displayList.add(GachaResultData(
              rarity: r, title: "魔法の\nジョウロ", icon: Icons.water_drop, color: Colors.cyan.shade200
            ));
            } 
          else if (type == 2) { addPoints += 500; 
          displayList.add(GachaResultData(
              rarity: r, title: "500 pt", icon: Icons.stars, color: Colors.yellow.shade200
            ));
          }
          else { 
            // ★変更点2： 新しい当たり「ガチャの実100個」を追加！
            addGachaFruits += 100; 
            
            displayList.add(GachaResultData(
              rarity: r, 
              title: "実 x100",    // カードに表示する名前
              icon: Icons.casino, // アイコン（実はカジノチップのアイコンが似合います）
              color: Colors.orange.shade300 // 色（低レアの実より少し濃くしました）
            ));
          }
          break;

case GachaRarity.high:
          if (isEventActive) {
            // ★ ここで運試し！ 50%ずつの確率で出し分けます
            if (random.nextBool()) {
              // コインの表なら「バレンタイン」
              save.obtainTree('valentine'); 
              gotTreeName = "バレンタインの木"; 
              displayList.add(GachaResultData(
                rarity: r, title: "バレンタイン\nの木", icon: Icons.favorite, color: Colors.pink.shade100, textColor: Colors.red
              ));
            } else {
              // コインの裏なら「ホワイトデー」
              save.obtainTree('whiteday'); // ※図鑑にwhitedayを追加しておくのを忘れずに！
              gotTreeName = "ホワイトデーの木";
              displayList.add(GachaResultData(
                rarity: r, title: "ホワイトデー\nの木", icon: Icons.card_giftcard, color: Colors.lightBlue.shade100, textColor: Colors.blue
              )); 
            }
          } else {
            // イベント期間外の処理（今まで通り）
            if (random.nextBool()) { 
              save.obtainTree('default'); 
              gotTreeName = "はじまりの木"; 
              displayList.add(GachaResultData(
                rarity: r, title: "はじまり\nの木", icon: Icons.park, color: Colors.green.shade200
              ));
            } else {
              addPoints += 10000;
              displayList.add(GachaResultData(
                rarity: r, title: "10,000 pt", icon: Icons.currency_yen, color: Colors.amber.shade300
              ));
            }
          }
          break;
                }
    }

    save.point += addPoints;
    save.gachaCount += addGachaFruits;

    if (addExp > 0) {
       final currentTree = save.currentTree;
       currentTree.exp += addExp;
       while (currentTree.exp >= 100 && currentTree.level < currentTree.maxLevel) {
         currentTree.level++;
         currentTree.exp -= 100; 
       }
    }

    if (hasWateringCan) {
      final currentTree = save.currentTree;
      currentTree.stage = 'red';
      currentTree.lastUpdated = DateTime.now().subtract(const Duration(hours: 3)); 
    }

    await save.save();

    setState(() {
      results = displayList;
    });

    // ■■■ ダイアログの作成 ■■■
    String message = "";
    
    if (gotTreeName.isNotEmpty) {
      message += "🎉 大当たり！「$gotTreeName」をゲット！\n\n";
    }
    if (hasWateringCan) message += "🚿 魔法のジョウロを獲得！\n";
    if (addExp > 0) message += "🧪 経験値肥料 ($addExp EXP) 獲得\n";
    if (addPoints > 0) message += "💰 $addPoints ポイント獲得\n";
    if (addGachaFruits > 0) message += "🍒 ガチャの実 $addGachaFruits個 獲得\n";

    if (message.isEmpty) message = "はずれ...？";

    showDialog(
      context: context,
      barrierDismissible: false, // ボタンを押すまで閉じないようにする
      builder: (_) => AlertDialog(
        title: const Text("ガチャ結果"),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          // ★★★ 2. 高レアが出た時だけ「シェアボタン」を表示 ★★★
          if (gotTreeName.isNotEmpty)
            ElevatedButton.icon(
              icon: const Icon(Icons.share, size: 18),
              label: const Text("シェアして100ptゲット！"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, 
                foregroundColor: Colors.white
              ),
              onPressed: () {
                // シェア機能を実行
                _shareAndGetPoints(gotTreeName);
              },
            ),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("閉じる"),
          ),
        ],
      ),
    );
  }

  // ★★★ 3. シェア機能を実行する関数 ★★★
// ▼▼▼ ここから書き換え ▼▼▼
  Future<void> _shareAndGetPoints(String treeName) async {
    // 1. シェアする文章とURL
    final String text = "やったー！ガチャで「$treeName」をゲットしたよ！\nみんなも一緒に遊ぼう！ #MyGardenApp";
    // ※↓ここはリリースの時に自分のアプリのURLに変えてね
    final String appUrl = "https://apps.apple.com/jp/app/id6757453654"; 

    // 2. ★ここを修正！
    // shareWithResult（新しい機能）ではなく、share（昔からある確実な機能）を使います。
    // これならエラーが出ません。
    await Share.share('$text\n$appUrl');

    // 3. ポイント付与
    // 古い機能だと「本当に投稿したか」の判定ができないので、
    // 「シェアボタンを押して画面が開いた」時点で成功とみなしてポイントをあげちゃいます！
    // （ユーザーにとっても優しい仕様になります）
    setState(() {
      save.point += 100;
    });
    await save.save();

    // 4. お礼のメッセージ
    if (mounted) {
      Navigator.pop(context); // ダイアログを閉じる
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("シェアありがとうございます！100ポイントプレゼント！🎁")),
      );
    }
  }
  // ▲▲▲ ここまで書き換え ▲▲▲
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 193, 111),
      appBar: AppBar(title: const Text("ガチャ")),
      bottomNavigationBar: const SafeArea(child: MyBannerAd()),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text("ガチャの実：${save.gachaCount}"),
            const SizedBox(height: 5),
            const GachaInfoBoard(),
            const SizedBox(height: 20),
// ▼▼▼ ここから書き換え ▼▼▼
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // 真ん中に寄せる
              children: [
                // 1. 単発ガチャボタン
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                    foregroundColor: Colors.white,
                    // 横並びになるので、横幅の余白(padding)を少し減らしておくと安心です
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: save.gachaCount >= 10 ? rollSingle : null,
                  child: const Text("🎁 単発", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                
                const SizedBox(width: 16), // ★ ボタンとボタンの間の隙間（横幅）

                // 2. 10連ガチャボタン
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: save.gachaCount >= 100 ? rollTen : null,
                  child: const Text("✨ 10連", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            // ▲▲▲ ここまで書き換え ▲▲▲            const Divider(),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("🎉 ガチャ結果", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: results.map((data) { return GachaResultCard(data: data); }).toList(),
              ),
            ),
            const SizedBox(height: 50), 
          ],
        ),
      ),
    );
  }
}