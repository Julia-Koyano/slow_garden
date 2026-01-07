import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class MyBannerAd extends StatefulWidget {
  const MyBannerAd({super.key});

  @override
  State<MyBannerAd> createState() => _MyBannerAdState();
}

class _MyBannerAdState extends State<MyBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // ★ ここに「あなたの本物のバナーID」を入れてください！
  // 今はテスト用IDが入っています
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-1785440822114696/2117448677' // Android
      : 'ca-app-pub-1785440822114696/9080659883'; // iOS

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('バナー広告の読み込み失敗: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 読み込み完了していたら表示、まだなら空っぽの箱を表示
    if (_isLoaded && _bannerAd != null) {
      return SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    // 読み込み中は高さ50の透明な箱を置いておく（レイアウトがガクッとなるのを防ぐ）
    return const SizedBox(height: 50);
  }
}