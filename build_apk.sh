#!/usr/bin/env bash
#==============================================================
# [PiliPlus Learning] APK 完全离线打包脚本
# 用法: 在项目根目录执行 bash build_apk.sh
#
# 完全离线说明:
#   - Git 依赖: 已全部内置于 vendor/ 目录,无需访问 GitHub
#   - pub.dev 依赖: 已全部内置于 vendor/pub/ 目录,无需访问外网
#   - Gradle 分发: 使用阿里云镜像下载(仅首次构建需要)
#   - Maven 仓库: 使用阿里云镜像(google/central/public)
#
# 前提: 本地已安装 Flutter SDK (>=3.38.0)
#==============================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> [1/4] 设置国内环境变量"
export PUB_HOSTED_URL="https://pub.flutter-io.cn"
export FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
export PUB_CACHE="$SCRIPT_DIR/vendor/pub"
export GRADLE_USER_HOME="$SCRIPT_DIR/vendor/gradle_home"

echo "==> [2/4] flutter clean"
flutter clean

echo "==> [3/4] flutter pub get (离线模式,使用本地 vendor/pub/ 缓存)"
flutter pub get --offline

echo "==> [4/4] flutter build apk --release (离线模式)"
flutter build apk --release --offline \
  --target-platform android-arm64,android-arm

echo ""
echo "============================================"
echo "  打包完成!"
echo "  APK 路径: build/app/outputs/flutter-apk/app-release.apk"
echo "============================================"
