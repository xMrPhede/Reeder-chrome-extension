chrome.runtime.onInstalled.addListener(async (details) => {
  if (details.reason === "install") {
    chrome.storage.local.set({ onboardingShown: true });
    chrome.tabs.create({
      url: "https://github.com/xMrPhede/Reeder-chrome-extension#setup",
    });
  }
});
