// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TabBridge contributors.
import Foundation

enum ADB {
    static var executable: URL? {
        if let tools = Bundle.main.resourceURL?.appendingPathComponent("Tools/adb"), FileManager.default.isExecutableFile(atPath: tools.path) { return tools }
        for path in ["/opt/homebrew/bin/adb", "/usr/local/bin/adb"] where FileManager.default.isExecutableFile(atPath: path) { return URL(fileURLWithPath: path) }
        return nil
    }
    static func run(_ arguments: [String], timeout: Double = 20) async throws -> String {
        guard let executable else { throw NSError(domain: "TabBridge", code: 1, userInfo: [NSLocalizedDescriptionKey: "USB aracı bulunamadı. Uygulamanın tam paketini kullan."]) }
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process(), output = Pipe(), errors = Pipe()
                process.executableURL = executable; process.arguments = arguments
                process.standardOutput = output; process.standardError = errors
                let expiry = DispatchWorkItem { if process.isRunning { process.terminate() } }
                do {
                    try process.run()
                    DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: expiry)
                    let data = output.fileHandleForReading.readDataToEndOfFile()
                    let errorData = errors.fileHandleForReading.readDataToEndOfFile()
                    process.waitUntilExit(); expiry.cancel()
                    guard process.terminationStatus == 0 else {
                        let detail = String(decoding: errorData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
                        throw NSError(domain: "TabBridge.USB", code: Int(process.terminationStatus), userInfo: [NSLocalizedDescriptionKey: detail.isEmpty ? "USB bağlantı isteği tamamlanamadı." : detail])
                    }
                    continuation.resume(returning: String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines))
                } catch { expiry.cancel(); continuation.resume(throwing: error) }
            }
        }
    }
}
