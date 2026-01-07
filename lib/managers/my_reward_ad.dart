import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// 動画広告（リワード）を管理する便利なクラス
class MyRewardAd {
  RewardedAd? _rewardedAd;
  int _retryLoadAttempts = 0;
  final int maxFailedLoadAttempts = 3;

  // テスト用ID（本番用IDに置き換えるときはここだけ変えればOK！）
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-1785440822114696/1565966096' // Android
      : 'ca-app-pub-1785440822114696/8998374183'; // iOS

  // 読み込み開始
  void load() {
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('動画広告の読み込み成功');
          _rewardedAd = ad;
          _retryLoadAttempts = 0;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('動画広告の読み込み失敗: $error');
          _rewardedAd = null;
          _retryLoadAttempts++;
          if (_retryLoadAttempts < maxFailedLoadAttempts) {
            load(); // 失敗しても数回はリトライする
          }
        },
      ),
    );
  }

  // 広告を表示する
  // onReward: 広告を見終わった後に実行したい処理（ポイント付与など）を渡す
  void show({
    required BuildContext context,
    required Function onReward,
  }) {
    // 準備ができていない場合
    if (_rewardedAd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('広告の読み込み中です。もう一度ボタンを押してください')),
      );
      load(); // 再読み込みを試みる
      return;
    }

    // 表示の設定
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedAd ad) {
        ad.dispose();
        load(); // 見終わったら、次のためにすぐ新しいのを読み込んでおく
      },
      onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
        ad.dispose();
        load();
      },
    );

    // いざ表示！
    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        // 見終わった！報酬を与える
        onReward();
      },
    );
    _rewardedAd = null; // 使い終わったので空にする
  }

  // 終了処理
  void dispose() {
    _rewardedAd?.dispose();
  }
}