#!/usr/bin/env bash
# ============================================================
# Proma fork：一键修复「bun install 后运行时依赖实体缺失」
#
# 背景：每次上游更新合并后跑 bun install，bun 都不会把冲突版本的
# 嵌套依赖实体化（例如 pi-coding-agent 需要的 jiti@2.7.0 /
# highlight.js@10.7.3 被 vite 生态的 1.21.7 / 11.11.1 顶到顶层），
# 导致 Agent 运行时报 ERR_MODULE_NOT_FOUND 或 ERR_PACKAGE_PATH_NOT_EXPORTED
# （症状：发消息后直接"完成"、没有输出、无法停止）。
#
# 修复流程：bun install 实体化依赖 → 干净重同步 electron 运行时副本
# → 校验关键嵌套版本与 Electron 二进制。
# ============================================================
set -euo pipefail
cd "$(dirname "$0")"

export https_proxy="${https_proxy:-http://127.0.0.1:7890}"
export http_proxy="${http_proxy:-http://127.0.0.1:7890}"
export all_proxy="${all_proxy:-socks5://127.0.0.1:7890}"
export ELECTRON_MIRROR="${ELECTRON_MIRROR:-https://npmmirror.com/mirrors/electron/}"

echo "==> 1/5 重新安装依赖（实体化嵌套版本）"
bun install

echo "==> 2/5 干净重同步 electron 运行时副本"
bun run --filter='@proma/electron' sync:runtime-deps

echo "==> 3/5 校验关键嵌套依赖"
check_nested() {
  local label="$1" pkg="$2" expect="$3"
  local f="node_modules/@earendil-works/pi-coding-agent/node_modules/$pkg/package.json"
  if [ ! -f "$f" ]; then
    echo "  ❌ $label 缺失（$f）"
    return 1
  fi
  local v
  v=$(grep '"version"' "$f" | head -1 | sed -E 's/.*"([0-9][^"]*)".*/\1/')
  if [ "$v" = "$expect" ]; then
    echo "  ✅ $label $v"
  else
    echo "  ⚠️  $label 版本 $v（期望 $expect），向上游 #2003 合并后再看"
  fi
}
check_nested "jiti        " jiti 2.7.0 || true
check_nested "highlight.js " highlight.js 10.7.3 || true

echo "==> 4/5 校验 Electron 二进制"
if [ ! -d "node_modules/electron/dist/Electron.app" ]; then
  echo "  Electron 二进制缺失，重新安装..."
  node node_modules/electron/install.js
fi
node_modules/.bin/electron --version

echo "==> 5/5 Electron 运行时副本中的 jiti"
if [ -f "apps/electron/node_modules/@earendil-works/pi-coding-agent/node_modules/jiti/package.json" ]; then
  echo "  ✅ 已同步"
else
  echo "  ⚠️ 同步后仍缺 jiti，尝试再跑一次 sync"
  bun run --filter='@proma/electron' sync:runtime-deps
fi

echo ""
echo "✅ 修复完成。重启 dev 后生效："
echo "   pkill -f electronmon; pkill -f 'Electron.*Proma'; bun run dev"