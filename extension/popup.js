document.addEventListener("DOMContentLoaded", async () => {
    const saveIcon = document.getElementById("saveIcon");
    const settings = document.getElementById("settings");
    const status = document.getElementById("status");
    const popup = document.querySelector(".popup");
    const overlay = document.getElementById("overlay");
  
    const setupLink = "https://github.com/xMrPhede/Reeder-chrome-extension#setup";
  
    // --- Show overlay when native host is missing ---
    function showOverlay() {
        const main = popup.querySelector("main");
        if (main) {
          main.style.pointerEvents = "none";
        }
        overlay.style.display = "flex";
      }
      
  
    // --- Check native host availability ---
    chrome.runtime.sendNativeMessage(
      "com.reeder.macshare",
      { cmd: "check" },
      (response) => {
        if (chrome.runtime.lastError || !response || response.status === "missing") {
          console.warn("Native app missing or unreachable:", chrome.runtime.lastError);
          showOverlay();
        } else {
          // Native app found, ensure overlay is hidden
          overlay.style.display = "none";
          popup.style.opacity = "1";
          popup.style.pointerEvents = "auto";
        }
      }
    );
  
    // --- Share to Reeder ---
    async function shareToReeder() {
      status.textContent = "Saving...";
      const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
      if (!tab?.url) return;
  
      chrome.runtime.sendNativeMessage(
        "com.reeder.macshare",
        { url: tab.url },
        (response) => {
          if (chrome.runtime.lastError) {
            status.innerHTML = `Connector not found.<br><code>curl -fsSL https://raw.githubusercontent.com/xMrPhede/Reeder-chrome-extension/main/install.sh | bash</code>`;
            console.error("Native host error:", chrome.runtime.lastError.message);
            return;
          }
  
          if (response && response.status === "ok") {
            status.textContent = "Sent to Reeder!";
            setTimeout(() => (status.textContent = ""), 2500);
          } else {
            status.textContent = "Unexpected response.";
          }
        }
      );
    }
  
    saveIcon.addEventListener("click", shareToReeder);
    settings.addEventListener("click", () => chrome.tabs.create({ url: setupLink }));
  });
  