// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TabBridge contributors.
import AppKit
import SwiftUI

@MainActor final class TabAppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var item: NSStatusItem!
    let model = TabModel.shared
    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 570, height: 790), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "TabBridge"; window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: TabMainView(model: model)); window.center()
        model.showWindow = { [weak self] in self?.show() }
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "display.2", accessibilityDescription: "TabBridge")
        let menu = NSMenu()
        for (title, action) in [("TabBridge’i aç", #selector(show)), ("Kablolu başlat", #selector(usb)), ("Kablosuz başlat", #selector(wifi)), ("Bağlantıyı kes", #selector(stop)), ("Çıkış", #selector(quit))] {
            let entry = NSMenuItem(title: title, action: action, keyEquivalent: ""); entry.target = self; menu.addItem(entry)
        }
        item.menu = menu
        if !CommandLine.arguments.contains("--background") { show() }
    }
    @objc func show() { model.activated(); window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
    @objc func usb() { model.connect(.usb) }
    @objc func wifi() { model.connect(.wifi) }
    @objc func stop() { model.stop() }
    @objc func quit() { model.stop(); NSApp.terminate(nil) }
    func applicationDidBecomeActive(_ notification: Notification) { model.activated() }
    func applicationWillTerminate(_ notification: Notification) { model.stop() }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func application(_ app: NSApplication, open urls: [URL]) {
        for url in urls where url.scheme == "tabbridge" {
            model.record("Widget bağlantısı: \(url.host ?? "setup")")
            if let mode = TabTransport(rawValue: url.host ?? "") { model.connect(mode) }
            else { show() }
        }
    }
}
MainActor.assumeIsolated {
    let application = NSApplication.shared
    let tabDelegate = TabAppDelegate()
    application.setActivationPolicy(.accessory); application.delegate = tabDelegate; application.run()
}
