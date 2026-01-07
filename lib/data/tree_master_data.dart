// lib/data/tree_master_data.dart
import 'package:flutter/material.dart';
import 'package:snowfall_or_anythings/snowfall_or_anythings.dart';

// 1. 木のデータ（設定）を入れる箱を作る
class TreeConfig {
  final String name;           // 木の名前
  final String treeImage;      // 木の画像パス
  final String bgImage;        // 背景画像のパス
  final ParticleType particle; // エフェクトの種類
  final Color particleColor;   // エフェクトの色
  final String flowerImage;     // 花
  final String fruitGreenImage; // 青い実
  final String fruitRedImage;   // 赤い実
  final double fruitBottom; // 実の高さ（下からの距離）
  final double treeHeight;  // 木の大きさ
  final double fruitSize;
  final double treeOffsetX;

  const TreeConfig({
    required this.name,
    required this.treeImage,
    required this.bgImage,
    required this.particle,
    required this.particleColor,
    required this.flowerImage,
    required this.fruitGreenImage,
    required this.fruitRedImage,
    this.fruitBottom = 170.0, // 指定しなければ 170 になる
    this.treeHeight = 350.0,  // 指定しなければ 350 になる
    this.fruitSize = 80.0,
    this.treeOffsetX = 0.0,
  });
}

// 2. IDごとの設定をリスト化する（ここさえ書き足せば、木が増やせる！）
class TreeMasterData {
  static const Map<String, TreeConfig> _data = {
    // ▼ はじまりの木
    'default': TreeConfig(
      name: 'はじまりの木',
      treeImage: 'assets/images/tree.png',
      bgImage: 'assets/images/garden_bg.png',
      particle: ParticleType.leaf,
      particleColor: Colors.green,
      flowerImage: 'assets/images/flower.png',
      fruitGreenImage: 'assets/images/fruit_green.png',
      fruitRedImage: 'assets/images/fruit_red.png',
    ),
    
    // ▼ バレンタインの木（ここに追加！）
    'valentine': TreeConfig(
      name: 'バレンタインの木',
      treeImage: 'assets/images/valentine/tree_valentine.png', // 画像を用意してね
      bgImage: 'assets/images/valentine/bg_valentine.png',     // 背景も用意してね
      particle: ParticleType.heart,
      particleColor: Color.fromARGB(255, 255, 56, 122),
      flowerImage: 'assets/images/valentine/flower_val.png',     // チョコの蕾とか？
      fruitGreenImage: 'assets/images/valentine/fruit_g_val.png', // まだ白いハートチョコとか
      fruitRedImage: 'assets/images/valentine/fruit_r_val.png',
      fruitBottom: 200.0, // ちょっと下に下げる（枝が低い場合など）
      fruitSize: 70.0,
      treeOffsetX: 20.0, // 右に20ピクセルずらす
      // treeOffsetX: -20.0, // 左にずらしたいときはマイナスをつける
    ),

    // ▼ホワイトデー
    'whiteday': TreeConfig(
      name: 'ホワイトデーの木',
      treeImage: 'assets/images/valentine/tree_whiteday.png',
      bgImage: 'assets/images/valentine/bg_whiteday.png',
      particle: ParticleType.heart, 
      particleColor: Color.fromARGB(255, 255, 255, 255),
      flowerImage: 'assets/images/valentine/flower_whi.png',     // チョコの蕾とか？
      fruitGreenImage: 'assets/images/valentine/fruit_g_whi.png', // まだ白いハートチョコとか
      fruitRedImage: 'assets/images/valentine/fruit_r_whi.png',
      fruitBottom: 200.0, // ちょっと下に下げる（枝が低い場合など）
      fruitSize: 70.0,
      treeOffsetX: 20.0, // 右に20ピクセルずらす
    ),
  };

  // IDを渡すとデータを返してくれる関数
  static TreeConfig getConfig(String id) {
    // もし知らないIDが来たら、とりあえずdefaultを返す（エラー防止）
    return _data[id] ?? _data['default']!;
  }
}