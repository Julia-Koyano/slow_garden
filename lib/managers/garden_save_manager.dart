import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserTree {
  final String id;        // 木の種類 (default, starbucks)
  String stage;           // flower, green, red
  DateTime lastUpdated;   // 最後に成長した時間

  // ▼ 育成データ
  int level;
  int exp;
  int rank;

  UserTree({
    required this.id,
    this.stage = 'flower', // 初期状態
    DateTime? lastUpdated,
    this.level = 1,
    this.exp = 0,
    this.rank = 0,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  int get maxLevel => 40 + (rank * 10);

  double get harvestMultiplier {
    if (level >= 100) return 2.0;
    if (level >= 50) return 1.5;
    return 1.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stage': stage,
      'lastUpdated': lastUpdated.toIso8601String(),
      'level': level,
      'exp': exp,
      'rank': rank,
    };
  }

  factory UserTree.fromJson(Map<String, dynamic> json) {
    return UserTree(
      id: json['id'] ?? 'default',
      stage: json['stage'] ?? 'flower',
      lastUpdated: DateTime.parse(json['lastUpdated']),
      level: json['level'] ?? 1,
      exp: json['exp'] ?? 0,
      rank: json['rank'] ?? 0,
    );
  }
}

class GardenSaveManager {
  GardenSaveManager._();
  static final instance = GardenSaveManager._();

  int point = 0;
  int gachaCount = 0;
  bool isDoubleGrowth = false;
  
  // ここに宣言済みですね！（OK！）
  bool isTutorialSeen = false; 
  
  DateTime? doubleGrowthEndTime;
  List<String> giftHistory = [];

  List<UserTree> myTrees = [];
  int currentTreeIndex = 0;

  // 今庭にある木を取得
  UserTree get currentTree {
    if (myTrees.isEmpty) myTrees.add(UserTree(id: 'default'));
    if (currentTreeIndex >= myTrees.length) currentTreeIndex = 0;
    return myTrees[currentTreeIndex];
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('point', point);
    await prefs.setInt('gachaCount', gachaCount);
    await prefs.setBool('isDoubleGrowth', isDoubleGrowth);
    
    // ★★★ 追加：ここで「見たかどうか」を保存します ★★★
    await prefs.setBool('isTutorialSeen', isTutorialSeen);

    if (doubleGrowthEndTime != null) {
      await prefs.setString('doubleGrowthEndTime', doubleGrowthEndTime!.toIso8601String());
    } else {
      await prefs.remove('doubleGrowthEndTime');
    }
    await prefs.setStringList('giftHistory', giftHistory);

    final String treesJson = jsonEncode(myTrees.map((t) => t.toJson()).toList());
    await prefs.setString('myTrees', treesJson);
    await prefs.setInt('currentTreeIndex', currentTreeIndex);
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    point = prefs.getInt('point') ?? 0;
    gachaCount = prefs.getInt('gachaCount') ?? 0;
    isDoubleGrowth = prefs.getBool('isDoubleGrowth') ?? false;
    
    // ★★★ 追加：ここで読み込みます（なければ false になる） ★★★
    isTutorialSeen = prefs.getBool('isTutorialSeen') ?? false;

    final end = prefs.getString('doubleGrowthEndTime');
    if (end != null) doubleGrowthEndTime = DateTime.parse(end);
    giftHistory = prefs.getStringList('giftHistory') ?? [];

    final String? treesJson = prefs.getString('myTrees');
    if (treesJson != null) {
      final List<dynamic> decoded = jsonDecode(treesJson);
      myTrees = decoded.map((item) => UserTree.fromJson(item)).toList();
    } else {
      myTrees = [UserTree(id: 'default')];
    }
    currentTreeIndex = prefs.getInt('currentTreeIndex') ?? 0;
  }
  
  void addGift(String url) {
    giftHistory.add(url);
    save();
  }

  void obtainTree(String newTreeId) {
    try {
      final existingTree = myTrees.firstWhere((t) => t.id == newTreeId);
      if (existingTree.rank < 6) {
        existingTree.rank++;
        // ランクアップ回復
        existingTree.stage = 'flower';
        existingTree.lastUpdated = DateTime.now();
      } else {
        point += 1000; 
      }
    } catch (e) {
      myTrees.add(UserTree(id: newTreeId));
    }
    save();
  }
  
  void switchTree(int index) {
    if (index >= 0 && index < myTrees.length) {
      currentTreeIndex = index;
      save();
    }
  }
}