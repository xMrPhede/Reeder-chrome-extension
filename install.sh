#!/usr/bin/env bash
set -e

# =====================================================
# Reeder Chrome Extension - Native Connector Installer
# Author: Federico Granata
# =====================================================

echo ""
echo "🚀 Installing Reeder native connector for macOS..."
echo "===================================================="

# --- Variables ---
APP_NAME="Reeder"
HOST_NAME="com.reeder.macshare"
INSTALL_DIR="/usr/local/bin"
SUPPORT_DIR="$HOME/Library/Application Support"
SWIFT_SRC="macshare.swift"
HOST_SCRIPT="macshare_host"
MANIFEST_TEMPLATE="native-messaging-host.json"

# --- Ensure Swift is available ---
if ! command -v swiftc &>/dev/null; then
  echo "❌ Swift compiler not found. Please install Xcode Command Line Tools first."
  echo "Run: xcode-select --install"
  exit 1
fi

# --- Create binaries directory ---
sudo mkdir -p "$INSTALL_DIR"
sudo chmod 755 "$INSTALL_DIR"

# --- Compile Swift binary ---
echo "🛠  Compiling native Swift binary..."
if [ -f "$SWIFT_SRC" ]; then
  sudo swiftc "$SWIFT_SRC" -o "$INSTALL_DIR/macshare"
  echo "✅ macshare compiled successfully."
else
  echo "❌ Swift source file '$SWIFT_SRC' not found."
  exit 1
fi

# --- Install host bridge ---
if [ -f "$HOST_SCRIPT" ]; then
  sudo cp "$HOST_SCRIPT" "$INSTALL_DIR/"
  sudo chmod +x "$INSTALL_DIR/$HOST_SCRIPT"
  echo "✅ Host bridge installed."
else
  echo "❌ Host bridge script '$HOST_SCRIPT' not found."
  exit 1
fi

# --- Install manifests for all Chromium browsers ---
echo "🧩 Registering native messaging manifests..."

browsers=("Google/Chrome" "BraveSoftware/Brave-Browser" "Microsoft Edge" "Vivaldi" "Arc" "Chromium")
for browser in "${browsers[@]}"; do
  browser_dir="$SUPPORT_DIR/$browser/NativeMessagingHosts"
  mkdir -p "$browser_dir"
  manifest_path="$browser_dir/$HOST_NAME.json"

  cat >"$manifest_path" <<EOF
{
  "name": "$HOST_NAME",
  "description": "Native messaging host for Reeder Chrome Extension",
  "path": "$INSTALL_DIR/$HOST_SCRIPT",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://__EXTENSION_ID__/","edge-extension://__EXTENSION_ID__/"
  ]
}
EOF
  echo "✅ Manifest installed for: $browser"
done

# --- Permissions ---
sudo chmod +x "$INSTALL_DIR/macshare"
sudo chmod +x "$INSTALL_DIR/$HOST_SCRIPT"

# --- Success message ---
echo ""
echo "🎉 Installation complete!"
echo "You can now use the 'Share to Reeder' button in your browser."
echo ""
echo "If you installed the extension manually from GitHub, replace '__EXTENSION_ID__' in the manifests"
echo "with your actual extension ID (found in chrome://extensions under 'Details')."
echo ""
echo "Done ✅"
