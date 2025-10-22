#!/usr/bin/env swift
import AppKit
import Foundation

let targetServiceName = "app.reeder.SaveLink" 

guard CommandLine.arguments.count > 1 else {
    print("Usage: macshare <url>")
    exit(1)
}

let urlString = CommandLine.arguments[1]
guard let url = URL(string: urlString) else {
    print("Invalid URL: \(urlString)")
    exit(1)
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

if let service = NSSharingService(named: NSSharingService.Name(targetServiceName)) {
    print("Found service: \(service.title)")
    service.perform(withItems: [url])
    RunLoop.main.run(until: Date().addingTimeInterval(10))
} else {
    print("⚠️ Service \(targetServiceName) not found.")
    print("Available services for URL:")
    if #available(macOS 13.0, *) {
        let picker = NSSharingServicePicker(items: [url])
        print("macOS 13+: direct enumeration is deprecated, use a known service identifier instead.")
    } else {
        for service in NSSharingService.sharingServices(forItems: [url]) {
            print("• \(service.title) — \(service.value(forKey:"name") ?? "unknown")")
        }
    }
    exit(2)
}

