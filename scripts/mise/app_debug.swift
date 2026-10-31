import Foundation

let config = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(filePath: "config.json"))) as! [String: Any]
let targets = (config["apps"] as! [String: Any])["targets"] as! [String: Any]
let macos = (targets["apple"] as! [String: Any])["macos"] as! [String: Any]
let name = Notification.Name("\(macos["bundleIdentifier"] as! String).debug")
DistributedNotificationCenter.default().postNotificationName(name, object: CommandLine.arguments[1], userInfo: nil, deliverImmediately: true)
