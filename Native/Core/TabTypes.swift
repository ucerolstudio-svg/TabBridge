// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TabBridge contributors.
import Foundation

enum TabTransport: String, Codable, CaseIterable { case usb, wifi
    var title: String { self == .usb ? "Kablolu" : "Kablosuz" }
    var symbol: String { self == .usb ? "cable.connector" : "wifi" }
}
struct TabSnapshot: Codable, Equatable {
    var phase = "Hazır"
    var device = "Galaxy Tab"
    var transport: TabTransport?
    var connected = false
    var updated = Date()
}
struct USBDevice: Identifiable, Equatable {
    var id: String
    var state: String
    var name: String
    var authorized: Bool { state == "device" }
}
enum USBInventory {
    static func parse(_ value: String) -> [USBDevice] {
        value.split(whereSeparator: \.isNewline).compactMap { line in
            let columns = line.split(whereSeparator: \.isWhitespace).map(String.init)
            guard columns.count >= 2, !line.hasPrefix("List of"), !line.hasPrefix("*"),
                  ["device", "unauthorized", "offline", "no"].contains(columns[1]),
                  !columns[0].contains(":"), !columns[0].hasPrefix("emulator-") else { return nil }
            let model = columns.first { $0.hasPrefix("model:") }?.dropFirst(6).replacingOccurrences(of: "_", with: " ")
            return USBDevice(id: columns[0], state: columns[1], name: model ?? "Android tablet")
        }
    }
    static func choose(_ devices: [USBDevice], preferred: String) -> USBDevice? {
        if let saved = devices.first(where: { $0.id == preferred }) { return saved }
        return devices.count == 1 ? devices.first : nil
    }
}
