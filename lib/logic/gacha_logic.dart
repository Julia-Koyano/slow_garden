import 'dart:math';

final random = Random();

enum GachaRarity { low, mid, high }

// 単発・通常抽選
GachaRarity drawNormal() {
  final r = random.nextDouble();

  if (r < 0.01) return GachaRarity.high;
  if (r < 0.11) return GachaRarity.mid;
  return GachaRarity.low;
}

// 10連確定枠
GachaRarity drawGuaranteed() {
  return random.nextDouble() < 0.1
      ? GachaRarity.high
      : GachaRarity.mid;
}
