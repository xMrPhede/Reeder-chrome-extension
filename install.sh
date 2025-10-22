#!/usr/bin/env bash
set -e

REPO_URL="https://raw.githubusercontent.com/xmrphede/<repo>/main"
BIN_DIR="/usr/local/bin"
EDGE_NATIVE_DIR="$HOME/Library/Application Support/Microsoft Edge/NativeMessagingHosts"

echo "🚀 Installing macshare components..."

# 1. Install macshare (Swift binary)
echo "📦 Compiling macshare..."
curl -fsSL "$REPO_URL/macshare.swift" -o /tmp/macshare.swift
sudo swiftc /tmp/macshare.swift -o "$BIN_DIR/macshare"
echo "✅ macshare installed to $BIN_DIR/macshare"

# 2. Install bridge host
echo "📦 Installing macshare_host..."
sudo curl -fsSL "$REPO_URL/macshare_host" -o "$BIN_DIR/macshare_host"
sudo chmod +x "$BIN_DIR/macshare_host"
echo "✅ macshare_host installed to $BIN_DIR/macshare_host"

# 3. Install native messaging manifest for Edge
echo "📦 Installing native messaging manifest..."
mkdir -p "$EDGE_NATIVE_DIR"
curl -fsSL "$REPO_URL/com.reeder.macshare.json" -o "$EDGE_NATIVE_DIR/com.reeder.macshare.json"
echo "✅ Manifest installed to $EDGE_NATIVE_DIR"

# 4. Instructions for extension
echo ""
echo "🧭 Next step:"
echo "1. Open Edge → edge://extensions"
echo "2. Enable Developer Mode."
echo "3. Click 'Load unpacked' and select the edge-extension folder from this repo."
echo ""
echo "🎉 Installation complete! Click the Reeder icon in Edge to share pages instantly."
