chrome.action.onClicked.addListener(async (tab) => {
    if (!tab || !tab.url) return;
    chrome.runtime.sendNativeMessage(
      "com.reeder.macshare",
      { url: tab.url },
      (response) => {
        if (chrome.runtime.lastError) {
          console.error("Native messaging error:", chrome.runtime.lastError.message);
        } else {
          console.log("Shared:", response);
        }
      }
    );
  });
  