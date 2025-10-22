# Reeder Chrome Extension

**Reeder Chrome Extension** lets you send any webpage from your browser directly to the Reeder macOS app.
It integrates with Reeder’s native share system through a lightweight local companion app.

---

## Overview

This project consists of two components:

1. **Browser Extension (Chromium browsers)**
   Adds a toolbar button labeled “Share to Reeder.” Clicking it sends the current page to Reeder.

2. **macOS Native Connector**
   A Swift binary (`macshare`) and a bridge script (`macshare_host`) that enable communication between Chromium browsers and Reeder through macOS’s Share Extension system.

The two components communicate securely using Chromium’s **Native Messaging API**.

---

## Features

* One-click “Share to Reeder” button
* Automatic detection of the native connector
* Clear setup guidance if the connector is missing
* Works with Chrome, Edge, Brave, Vivaldi, Opera, and Arc
* Secure macOS native messaging bridge

---

## Setup

### 1. Install the Browser Extension

Install the extension from the Chrome Web Store (link placeholder):

**[Install Reeder Chrome Extension](https://chrome.google.com/webstore/detail/REPLACE_WITH_EXTENSION_ID)**

After installation, pin the extension to your toolbar.

When you first click the extension, it will check for the native connector and guide you through setup if needed.

---

### 2. Install the Native macOS Connector (automatic)

Open Terminal on your Mac and run:

```bash
curl -fsSL https://raw.githubusercontent.com/xMrPhede/Reeder-chrome-extension/main/install.sh | bash
```

When prompted select the Chromium browser you want to install the native app for. 

This command:

* Compiles and installs the Swift binary `macshare`
* Installs the bridge script `macshare_host`
* Registers the native messaging manifest for all supported Chromium browsers

---

## Manual Native App Installation

If you encounter issues with the automatic setup script, you can manually install the native connector.

1. **Compile the Swift app**

   ```bash
   git clone https://github.com/xMrPhede/Reeder-chrome-extension.git
   cd Reeder-chrome-extension
   swiftc macshare.swift -o /usr/local/bin/macshare
   sudo chmod +x /usr/local/bin/macshare
   ```

2. **Install the bridge script**

   ```bash
   sudo cp macshare_host /usr/local/bin/macshare_host
   sudo chmod +x /usr/local/bin/macshare_host
   ```

3. **Register the native messaging host**

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

---

## How It Works

1. The browser extension sends the current page URL to the native host (`com.reeder.macshare`).
2. The host (`macshare_host`) forwards the URL to the Swift binary (`macshare`).
3. The Swift app activates the macOS Share Extension for Reeder.
4. Reeder receives the link and saves it to your reading list (local or iCloud).

---

## Uninstallation

To remove the native connector and manifests:

```bash
sudo rm -f /usr/local/bin/macshare /usr/local/bin/macshare_host
rm -f ~/Library/Application\ Support/*/NativeMessagingHosts/com.reeder.macshare.json
```

Then remove the extension from your browser as you would any other.

---

## License

This project is open source under the MIT License.
See [LICENSE](LICENSE) for details.
