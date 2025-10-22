# Reeder Chrome Extension

<div align="center">

![Extension Logo](https://github.com/xMrPhede/Reeder-chrome-extension/blob/main/extension/icons/icon128.png)

[![Chrome Web Store](https://img.shields.io/chrome-web-store/v/your-extension-id)](https://chrome.google.com/webstore/detail/your-extension-id)
[![Chrome Web Store Users](https://img.shields.io/chrome-web-store/users/your-extension-id)](https://chrome.google.com/webstore/detail/your-extension-id)
[![GitHub license](https://img.shields.io/github/license/xMrPhede/Reeder-chrome-extension)](https://github.com/xMrPhede/Reeder-chrome-extension/blob/main/LICENSE)

</div>

---

## 📖 Overview

**Reeder Chrome Extension** lets you send the current webpage from your browser directly to the Reeder macOS app.
It integrates seamlessly with Reeder’s native share system through a lightweight local connector.

This project consists of two components:

1. **Browser Extension (for Chromium browsers)**
   Adds a toolbar button labeled **“Share to Reeder”** — clicking it sends the current page to your Reeder app.

2. **macOS Native Connector**
   A small Swift binary (`macshare`) and bridge script (`macshare_host`) that allow the browser to communicate with Reeder through macOS’s Share Extension system.

---

## 🚀 Features

* One-click **“Share to Reeder”** button
* Automatic detection of the native connector
* Clear setup guide when the connector is missing
* Works with **Chrome**, **Edge**, **Brave**, **Vivaldi**, **Opera**, and **Arc**
* Secure native messaging bridge for macOS

---

## ⚙️ Setup

### 1. Install the Browser Extension

Install directly from the Chrome Web Store:

**[→ Install Reeder Chrome Extension](https://chrome.google.com/webstore/detail/your-extension-id)**

Once installed, pin the extension to your toolbar.
On first use, it will check whether the native connector is present and provide setup instructions if not.

---

### 2. Install the Native macOS Connector (automatic)

Run this command in your Mac Terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/xMrPhede/Reeder-chrome-extension/main/install.sh | bash
```

This script:

* Compiles and installs the `macshare` Swift binary
* Installs the `macshare_host` bridge
* Registers the native messaging manifest for all supported Chromium browsers

Verify installation by running:

```bash
/usr/local/bin/macshare --help
```

---

## 🛠 Manual Native App Installation

If you experience issues with the installation script, follow these steps manually:

### 1. Compile the Swift App

```bash
git clone https://github.com/xMrPhede/Reeder-chrome-extension.git
cd Reeder-chrome-extension
swiftc macshare.swift -o /usr/local/bin/macshare
sudo chmod +x /usr/local/bin/macshare
```

### 2. Install the Bridge Script

```bash
sudo cp macshare_host /usr/local/bin/macshare_host
sudo chmod +x /usr/local/bin/macshare_host
```

### 3. Register the Native Messaging Host

Copy the manifest file to your browser’s native messaging directory:

```bash
# Chrome
mkdir -p ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/
cp com.reeder.macshare.json ~/Library/Application\ Support/Google/Chrome/NativeMessagingHosts/

# Edge
mkdir -p ~/Library/Application\ Support/Microsoft\ Edge/NativeMessagingHosts/
cp com.reeder.macshare.json ~/Library/Application\ Support/Microsoft\ Edge/NativeMessagingHosts/

# Brave
mkdir -p ~/Library/Application\ Support/BraveSoftware/Brave-Browser/NativeMessagingHosts/
cp com.reeder.macshare.json ~/Library/Application\ Support/BraveSoftware/Brave-Browser/NativeMessagingHosts/
```

Make sure the manifest points to the correct binary path:

```json
{
  "name": "com.reeder.macshare",
  "description": "Reeder macOS connector",
  "path": "/usr/local/bin/macshare_host",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://<your-extension-id>/"
  ]
}
```

---

## 🧩 How It Works

1. The extension sends the current tab’s URL to the native host `com.reeder.macshare`.
2. The host (`macshare_host`) forwards the URL to the Swift binary (`macshare`).
3. The Swift app triggers macOS’s Reeder Share Extension.
4. Reeder saves the page to your reading list (local or iCloud).

---

## ❌ Uninstallation

Remove the native components by running:

```bash
sudo rm -f /usr/local/bin/macshare /usr/local/bin/macshare_host
rm -f ~/Library/Application\ Support/*/NativeMessagingHosts/com.reeder.macshare.json
```

Then remove the extension from your browser as usual.

---

## 📝 License

This project is licensed under the **MIT License**.
See the [LICENSE](LICENSE) file for details.

---

<div align="center">

Made with ❤️ by Federico Granata

</div>
