#!/usr/bin/env bash
#==============================================================
# [PiliPlus Learning] APK 打包脚本
# 用法: 在项目根目录执行 bash build_apk.sh
#==============================================================
set -e

echo "==> [1/3] flutter clean"
flutter clean

echo "==> [2/3] flutter pub get"
flutter pub get

echo "==> [3/3] flutter build apk --release"
flutter build apk --release \
  --target-platform android-arm64,android-arm

echo ""
echo "============================================"
echo "  打包完成!"
echo "  APK 路径: build/app/outputs/flutter-apk/app-release.apk"
echo "============================================"
