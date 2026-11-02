import AppKit
import Foundation

let input = FileHandle.standardInput
let output = FileHandle.standardOutput
func readExact(_ count: Int) -> Data? {
    var result = Data()
    while result.count < count {
        let part = input.readData(ofLength: count - result.count)
        if part.isEmpty { return nil }
        result.append(part)
    }
    return result
}
func reply(_ object: [String: String]) {
    guard let body = try? JSONSerialization.data(withJSONObject: object) else { return }
    var length = UInt32(body.count)
    withUnsafeBytes(of: &length) { output.write(Data($0)) }
    output.write(body)
}
// Chrome enforces the exact extension allowlist in the installed manifest.
// Generate JSON here so paths containing quotes or backslashes remain valid.
if CommandLine.arguments.count == 4 && CommandLine.arguments[1] == "--manifest" {
    let manifest: [String: Any] = [
        "name": "com.reeder.macshare",
        "description": "Reeder native messaging connector",
        "path": CommandLine.arguments[2],
        "type": "stdio",
        "allowed_origins": ["chrome-extension://\(CommandLine.arguments[3])/"],
    ]
    output.write(try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys]))
    exit(0)
}
final class ShareDelegate: NSObject, NSSharingServiceDelegate {
    var done = false
    var failure: String?
    func sharingService(_ sharingService: NSSharingService, didShareItems items: [Any]) { done = true }
    func sharingService(_ sharingService: NSSharingService, didFailToShareItems items: [Any], error: Error) {
        failure = error.localizedDescription
        done = true
    }
}
while let header = readExact(4) {
    let length = header.withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) }
    guard length > 0, length <= 1024 * 1024, let body = readExact(Int(length)) else {
        reply(["status": "error", "error": "Invalid or incomplete message length"])
        break
    }
    guard let message = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any] else {
        reply(["status": "error", "error": "Invalid JSON"])
        continue
    }
    var sharingURL: URL?
    if message["cmd"] as? String != "check" {
        guard let value = message["url"] as? String, let url = URL(string: value),
              let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme), url.host != nil else {
            reply(["status": "error", "error": "A valid HTTP or HTTPS URL is required"])
            continue
        }
        sharingURL = url
    }
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    guard let service = NSSharingService(named: NSSharingService.Name("app.reeder.SaveLink")) else {
        reply(["status": "missing", "error": "Enable Reeder's Add to Reeder sharing extension in System Settings"])
        continue
    }
    if message["cmd"] as? String == "check" {
        reply(["status": "ok"])
        continue
    }
    guard let url = sharingURL else { continue }
    guard service.canPerform(withItems: [url]) else {
        reply(["status": "error", "error": "Reeder cannot share this URL"])
        continue
    }
    let delegate = ShareDelegate()
    service.delegate = delegate
    service.perform(withItems: [url])
    let deadline = Date().addingTimeInterval(60)
    while !delegate.done && Date() < deadline {
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }
    if let failure = delegate.failure {
        reply(["status": "error", "error": failure])
    } else if delegate.done {
        reply(["status": "ok"])
    } else {
        reply(["status": "error", "error": "Reeder sharing timed out"])
    }
    service.delegate = nil
}
