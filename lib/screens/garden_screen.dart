import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../managers/garden_save_manager.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import '../managers/my_banner_ad.dart'; 
import '../managers/my_reward_ad.dart';
import 'package:snowfall_or_anythings/snowfall_or_anythings.dart';

// ★前回作ったファイルをインポート（パスが違う場合は直してください）
import '../data/tree_master_data.dart'; 

final random = Random();

class GardenScreen extends StatefulWidget {
  const GardenScreen({super.key});

  @override
  State<GardenScreen> createState() => _GardenScreenState();
}

class _GardenScreenState extends State<GardenScreen> { 

  late Timer growthTimer;
  late Timer uiTimer;

  final save = GardenSaveManager.instance;
  bool _isHarvesting = false;
  static const int baseHarvestPoint = 100;
  
  // ★★★ 追加1：隠しコマンド用の連打カウンター ★★★
  int _debugTapCount = 0; 

  final MyRewardAd _rewardAdHelper = MyRewardAd();

  int get point => save.point;
  int get gachaCount => save.gachaCount;
  UserTree get tree => save.currentTree;

  bool get canHarvest => tree.stage == "red";

  @override
  void initState() {
    super.initState();
    save.load().then((_) {
      updateTreeStage();
      if (!save.isTutorialSeen) {
        // 画面の描画が終わってから表示するおまじない
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showTutorial();
          // 見終わったことにする
          save.isTutorialSeen = true;
          save.save();
        });
      }
      if (mounted) setState(() {});
    });
    _rewardAdHelper.load();

    growthTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      updateTreeStage();
      await save.save();
    });

    uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await AppTrackingTransparency.requestTrackingAuthorization();
    });
  }

  @override
  void dispose() {
    growthTimer.cancel();
    uiTimer.cancel();
    _rewardAdHelper.dispose();
    save.save();
    super.dispose();
  }

  void updateTreeStage() {
    final diff = DateTime.now().difference(tree.lastUpdated);
    final totalSeconds = save.isDoubleGrowth ? 3600 : 7200;

    if (diff.inSeconds >= totalSeconds) {
      tree.stage = "red";
    } else if (diff.inSeconds >= totalSeconds ~/ 2) {
      tree.stage = "green";
    } else {
      tree.stage = "flower";
    }
  }

  Duration getRemainingTime() {
    final needSeconds = save.isDoubleGrowth ? 3600 : 7200;
    final target = tree.lastUpdated.add(Duration(seconds: needSeconds));
    final diff = target.difference(DateTime.now());
    if (diff.isNegative) return Duration.zero;
    return diff;
  }

  String formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

 void showTutorial() {
    showDialog(
      context: context,
      barrierDismissible: true, // 背景をタップしたら閉じる
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent, // 背景を透明にして、角丸をきれいに出す
        insetPadding: const EdgeInsets.all(16), // 画面端からの隙間
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ★ チュートリアル画像
            ClipRRect(
              borderRadius: BorderRadius.circular(20), // 画像の角を丸くする
              child: Image.asset(
                'assets/images/tutorial.png', // 画像のパス（pubspec.yamlへの追加を忘れずに！）
                fit: BoxFit.contain, // 画面サイズに合わせて全体を表示
              ),
            ),
            
            // ★ 閉じるボタン（右上に配置）
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.black, size: 30),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white, // ボタンの背景を白くして見やすく
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            
          ],
        ),
      ),
    );
  }

// ■ 植え替えダイアログ（パワーアップ版）
  void showTreeSelectionDialog() {
    // 成長に必要な時間を計算（2倍モードなら3600秒、普通なら7200秒）
    final needSeconds = save.isDoubleGrowth ? 3600 : 7200;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("木の植え替え"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: save.myTrees.length,
            itemBuilder: (context, index) {
              final t = save.myTrees[index];
              final isSelected = (index == save.currentTreeIndex);
              final config = TreeMasterData.getConfig(t.id);

              // ★★★ ここで計算！「もう育ってるかな？」 ★★★
              final diff = DateTime.now().difference(t.lastUpdated);
              final isReady = diff.inSeconds >= needSeconds;

              return ListTile(
                leading: Icon(
                  Icons.park, 
                  color: isSelected ? Colors.green : Colors.grey,
                ),
                title: Text(config.name),
                subtitle: Text("Lv.${t.level} / Rank.${t.rank}"),
                
                // 「選択中」ならチェックマーク
                // 「選択してないけど育ってる」なら🍎マーク！
                trailing: isSelected 
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : (isReady 
                        ? const Row( // 収穫OKの表示
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.apple, color: Colors.red, size: 20),
                              Text("OK!", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ],
                          )
                        : null // まだなら何も表示しない
                      ),
                      
                onTap: () {
                  setState(() {
                    save.switchTree(index);
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("閉じる")),
        ],
      ),
    );
  }
  
  void harvestFruits() async {
    if (!canHarvest || _isHarvesting) return;
    _isHarvesting = true;
    bool isPointHarvest = random.nextBool();

    int estimatedPoint = (baseHarvestPoint * tree.harvestMultiplier).toInt();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text("収穫チャンス！"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isPointHarvest) ...[
                Text("合計 $estimatedPoint ポイント獲得！"),
                const SizedBox(height: 5),
                Text("(Lv.${tree.level} ボーナス適用中)", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 10),
                Text(
                  "動画広告を見ると\n【2倍の ${estimatedPoint * 2} ポイント】\nになります！",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                const Text("ガチャの実を10個獲得できます。"),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _applyHarvest(isPointHarvest, useAd: false);
              },
              child: const Text("そのまま受け取る"),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.movie),
              label: Text(isPointHarvest ? "2倍ゲット！" : "ポイントに変換！"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () {
                _rewardAdHelper.show(
                  context: context,
                  onReward: () {
                    Navigator.pop(context);
                    _applyHarvest(isPointHarvest, useAd: true);
                  },
                );
              },
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted && !_isHarvesting) {} else { _isHarvesting = false; }
    });
  }

  void _applyHarvest(bool isPointHarvest, {required bool useAd}) {
    int totalBasePoints = (baseHarvestPoint * tree.harvestMultiplier).toInt();
    
    setState(() {
      tree.exp += 30;
      if (tree.exp >= 100 && tree.level < tree.maxLevel) {
        tree.level++;
        tree.exp = 0;
      }

      tree.stage = "flower";
      tree.lastUpdated = DateTime.now();

      String message = "";
      if (isPointHarvest) {
        int finalPoint = useAd ? totalBasePoints * 2 : totalBasePoints;
        save.point += finalPoint;
        message = "$finalPoint ポイント獲得！";
      } else {
        if (useAd) {
          save.point += 10;
          message = "ボーナス！実を10ポイントに変換しました！";
        } else {
          save.gachaCount += 10;
          message = "ガチャの実を10個獲得！";
        }
      }

      save.isDoubleGrowth = false;
      save.save();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    });
  }
  
  void _activateDoubleSpeed() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("成長速度アップ"),
          content: const Text("動画広告を見て、次の収穫まで成長速度を2倍にしますか？"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("キャンセル")),
            ElevatedButton(
              onPressed: () {
                _rewardAdHelper.show(
                  context: context,
                  onReward: () {
                    Navigator.pop(context);
                    setState(() { save.isDoubleGrowth = true; });
                    save.save();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("成長速度が2倍になりました！")));
                  },
                );
              },
              child: const Text("広告を見て2倍！"),
            ),
          ],
        );
      },
    );
  }

 String getFruitImage(String stage, TreeConfig config) {
    switch (stage) {
      // ↓ config（図鑑の設定）から画像を取り出す
      case "flower": return config.flowerImage;    
      case "green": return config.fruitGreenImage; 
      case "red": return config.fruitRedImage;     
      default: return config.flowerImage;
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = getRemainingTime();

    // ★★★ 1. 現在の木の設定データをここで一括取得！ ★★★
    final config = TreeMasterData.getConfig(tree.id);

    return Scaffold(
      bottomNavigationBar: const SafeArea(child: MyBannerAd()),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min, // 中身の大きさに合わせる
        children: [
          // 1. 木の植え替えボタン（メイン）
          FloatingActionButton(
            heroTag: "tree_btn", // ★重要：ボタンが2つある時はこれが必要
            onPressed: showTreeSelectionDialog,
            backgroundColor: Colors.green,
            child: const Icon(Icons.park),
          ),
          
          const SizedBox(height: 12), // ボタンの間の隙間

          // 2. チュートリアルボタン（サブ）
          FloatingActionButton(
            heroTag: "tutorial_btn", // ★重要：こっちにも別の名前をつける
            onPressed: showTutorial,
            backgroundColor: Colors.white, // サブなので白にしてみる
            mini: true, // ★少し小さくして「サブ感」を出す（お好みで！）
            child: const Icon(Icons.help_outline, color: Colors.green),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,

      body: Stack(
        children: [
          // ★★★ 2. 背景画像をデータから取得 ★★★
          Positioned.fill(
            child: Image.asset(
              config.bgImage, 
              fit: BoxFit.cover
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text(canHarvest ? "収穫OK" : formatDuration(remaining), textAlign: TextAlign.center),
                          ),
                          const SizedBox(width: 12),
                          
                          // ★★★ 追加2：ここから隠しコマンド！ ★★★
                          GestureDetector(
                            onTap: () {
                              _debugTapCount++;
                              // 10回タップしたら発動！
                              if (_debugTapCount >= 10) {
                                setState(() {
                                  save.point += 10000; // 1万ポイントあげる
                                  save.save();
                                  _debugTapCount = 0; // カウントリセット
                                });
                                
                                // 分かりやすいようにメッセージを出す
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("🤫 デバッグモード：10,000ptゲット！"),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                            // 既存のチップをそのままchildにする
                            child: _StatusChip(icon: Icons.star, label: 'Pt', value: point),
                          ),
                          // ★★★ ここまで ★★★
                          
                          const SizedBox(width: 8),
                          _StatusChip(icon: Icons.casino, label: '実', value: gachaCount),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
                          child: Text(
                            // ★★★ 3. 木の名前をデータから取得 ★★★
                            "${config.name} (Lv.${tree.level})", 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Stack(
                          alignment: Alignment.center,
                          children: [
                            
                            // ★★★ 4. 木の画像をデータから取得 ★★★
                            // Transform.translate で包んで、位置をずらせるようにします
                            Transform.translate(
                              // x方向に config.treeOffsetX だけ移動、y方向は 0（そのまま）
                              offset: Offset(config.treeOffsetX, 0), 
                              
                              child: Image.asset(
                                config.treeImage, 
                                height: config.treeHeight, 
                              ),
                            ),
                            
                            // ★★★ 5. エフェクトの設定をデータから取得 ★★★
                            SizedBox(
                              height: 300,
                              width: 300,
                              child: SnowfallOrAnythings(
                                // keyをつけると、木を切り替えた瞬間にエフェクトもリセットされて綺麗です
                                key: ValueKey(tree.id), 

                                // データファイルに書いた設定を使います
                                particleType: config.particle,
                                particleColor: config.particleColor, 
                                
                                numberOfParticles: 10,
                                particleSpeed: 1.0,
                                particleSize: 10.0,
                              ),
                            ),

                            Positioned(
                              bottom: config.fruitBottom,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (i) {
                                  return GestureDetector(
                                    onTap: harvestFruits,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      child: Image.asset(
                                        getFruitImage(tree.stage, config),
                                        height: config.fruitSize,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: save.isDoubleGrowth ? null : _activateDoubleSpeed,
                          child: Text(save.isDoubleGrowth ? "成長速度2倍中！" : "成長速度を2倍にする"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  const _StatusChip({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [Icon(icon, size: 18), const SizedBox(width: 4), Text('$label: $value', style: const TextStyle(fontWeight: FontWeight.bold))]),
    );
  }
}