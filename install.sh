#!/usr/bin/env bash
set -euo pipefail

# User-level installation: no administrator privileges or system permission changes.
extension_id="kdmelpioblnhdphjcafpclindpmcjfgh"
browser="chrome"
source_dir=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --browser|--extension-id|--source-dir)
      [ "$#" -ge 2 ] || { echo "Missing value for $1" >&2; exit 1; }
      case "$1" in
        --browser) browser="$2" ;;
        --extension-id) extension_id="$2" ;;
        --source-dir) source_dir="$2" ;;
      esac
      shift 2 ;;
    *) echo "Usage: bash install.sh [--browser chrome|brave|edge|vivaldi|arc|chromium|opera] [--extension-id ID] [--source-dir PATH]" >&2; exit 1 ;;
  esac
done
[[ "$extension_id" =~ ^[a-p]{32}$ ]] || { echo "Invalid extension ID (expected 32 letters a-p)." >&2; exit 1; }
case "$browser" in
  chrome) browser_path="Google/Chrome" ;;
  brave) browser_path="BraveSoftware/Brave-Browser" ;;
  edge) browser_path="Microsoft Edge" ;;
  vivaldi) browser_path="Vivaldi" ;;
  arc) browser_path="Arc/User Data" ;;
  chromium) browser_path="Chromium" ;;
  opera) browser_path="com.operasoftware.Opera" ;;
  *) echo "Unsupported browser: $browser" >&2; exit 1 ;;
esac
[ "$(uname -s)" = Darwin ] || { echo "This connector requires macOS." >&2; exit 1; }
command -v swiftc >/dev/null || { echo "Install Xcode Command Line Tools first: xcode-select --install" >&2; exit 1; }
support="$HOME/Library/Application Support"
install_dir="$support/ReederChromeConnector"
manifest_dir="$support/$browser_path/NativeMessagingHosts"
manifest="$manifest_dir/com.reeder.macshare.json"
# Compile and generate JSON before touching the existing installation.
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/reeder-install.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT
if [ -n "$source_dir" ]; then
  cp "$source_dir/macshare.swift" "$tmp_dir/macshare.swift"
else
  curl --fail --silent --show-error --location --proto '=https' --proto-redir '=https' \
    https://raw.githubusercontent.com/xMrPhede/Reeder-chrome-extension/main/macshare.swift \
    -o "$tmp_dir/macshare.swift"
fi
swiftc -module-cache-path "$tmp_dir/module-cache" "$tmp_dir/macshare.swift" -o "$tmp_dir/macshare_host"
"$tmp_dir/macshare_host" --manifest "$install_dir/macshare_host" "$extension_id" > "$tmp_dir/manifest.json"
mkdir -p "$install_dir" "$manifest_dir"
backup_dir="$(mktemp -d "$install_dir/backup.XXXXXX")"
for name in macshare_host macshare.swift; do
  if [ -e "$install_dir/$name" ]; then cp -p "$install_dir/$name" "$backup_dir/$name"; fi
done
if [ -e "$manifest" ]; then cp -p "$manifest" "$backup_dir/com.reeder.macshare.json"; fi
# Copy to temporary siblings, then rename so readers never see partial files.
install -m 755 "$tmp_dir/macshare_host" "$install_dir/.macshare_host.new"
install -m 644 "$tmp_dir/macshare.swift" "$install_dir/.macshare.swift.new"
install -m 644 "$tmp_dir/manifest.json" "$manifest_dir/.com.reeder.macshare.json.new"
mv -f "$install_dir/.macshare_host.new" "$install_dir/macshare_host"
mv -f "$install_dir/.macshare.swift.new" "$install_dir/macshare.swift"
mv -f "$manifest_dir/.com.reeder.macshare.json.new" "$manifest"
echo "Installed connector: $install_dir/macshare_host"
echo "Registered for $browser: $manifest"
echo "Previous files (if any): $backup_dir"
echo "Enable Reeder's Add to Reeder sharing extension in System Settings, then open Share to Reeder in your browser."
