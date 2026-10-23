// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TabBridge contributors.
import AppKit
import Network
import Observation
import WidgetKit

struct WiFiTablet: Identifiable {
    var id: String
    var name: String
    var endpoint: NWEndpoint
}

@MainActor @Observable
final class TabModel {
    static let shared = TabModel()
    var wifiTablets: [WiFiTablet] = []
    var usbTablets: [USBDevice] = []
    var selectedWiFi = UserDefaults.standard.string(forKey: "selected-wifi") ?? ""
    var selectedUSB = UserDefaults.standard.string(forKey: "selected-usb") ?? ""
    var phase = "Hazır"
    var detail = "İlk bağlantıyı kur; sonra widget’tan tek dokunuşla başlat."
    var connected = false
    var busy = false
    var transport: TabTransport?
    var deviceName = "Galaxy Tab"
    var pairingSummary = "İlk Wi-Fi bağlantısından önce USB ile eşleştir."
    var screenPermission = false
    var inputPermission = false
    var logs: [String] = []
    var showWindow: (() -> Void)?
    private var browser: NWBrowser?
    private var sender: MacSender?
    private var operation: Task<Void, Never>?
    private var timeout: Task<Void, Never>?
    private var generation = 0
    private var pendingTransport: TabTransport?
    private var forwarded: (serial: String, port: String)?
    private var lastSnapshot: TabSnapshot?
    init() {
        refreshPermissions()
        let browser = NWBrowser(for: .bonjourWithTXTRecord(type: "_tabbridge-secure._tcp", domain: nil), using: .tcp)
        browser.browseResultsChangedHandler = { [weak self] results, _ in
            Task { @MainActor in
                guard let self else { return }
                self.wifiTablets = results.compactMap { result in
                    guard case .service(let name, _, _, _) = result.endpoint else { return nil }
                    var id = name
                    if case .bonjour(let txt) = result.metadata { id = txt["id"] ?? name }
                    return WiFiTablet(id: id, name: name, endpoint: result.endpoint)
                }.sorted { $0.name < $1.name }
                if self.selectedWiFi.isEmpty, self.wifiTablets.count == 1 { self.selectedWiFi = self.wifiTablets[0].id }
                if self.pendingTransport == .wifi, !self.busy, !self.wifiTablets.isEmpty { self.connect(.wifi) }
            }
        }
        browser.stateUpdateHandler = { [weak self] state in
            if case .failed(let error) = state { Task { @MainActor in self?.record("Ağ keşfi: \(error)") } }
        }
        browser.start(queue: .main); self.browser = browser
        exportSnapshot()
    }
    func record(_ text: String) { logs.append(text); if logs.count > 80 { logs.removeFirst(logs.count - 80) }; Log.info(text) }
    func refreshPermissions() {
        screenPermission = CGPreflightScreenCaptureAccess(); inputPermission = AXIsProcessTrusted()
    }
    func activated() {
        let wasGranted = screenPermission && inputPermission
        refreshPermissions()
        if !wasGranted, screenPermission, inputPermission, let pendingTransport, !busy, !connected { connect(pendingTransport) }
    }
    func grantScreen() { _ = CGRequestScreenCaptureAccess(); openPrivacy("Privacy_ScreenCapture") }
    func grantInput() { _ = InputInjector.ensureAccessibilityPermission(); openPrivacy("Privacy_Accessibility") }
    func openPrivacy(_ anchor: String) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") { NSWorkspace.shared.open(url) }
    }
    func refreshUSB() {
        Task {
            do {
                usbTablets = USBInventory.parse(try await ADB.run(["devices", "-l"]))
                if let pick = USBInventory.choose(usbTablets, preferred: selectedUSB) { selectedUSB = pick.id }
            } catch { record(error.localizedDescription); detail = "USB aracı hazır değil. Kurulum rehberini kontrol et." }
        }
    }
    func connect(_ mode: TabTransport) {
        refreshPermissions()
        pendingTransport = mode
        guard screenPermission && inputPermission else {
            phase = "İzinleri tamamla"; detail = "Ekran aktarımı ve S Pen için aşağıdaki iki Mac iznini bir kez ver."; showWindow?(); exportSnapshot(); return
        }
        if connected && transport == mode { return }
        stop(clearPending: false)
        pendingTransport = mode; transport = mode
        generation += 1; let token = generation
        busy = true; phase = "Bağlanıyor"; detail = mode == .usb ? "Tablet USB bağlantısı hazırlanıyor…" : "Tablet aynı Wi-Fi ağında aranıyor…"
        exportSnapshot()
        operation = Task { [weak self] in
            guard let self else { return }
            do {
                let endpoint: NWEndpoint
                var name: String
                var credential: PairedTablet?
                if mode == .usb {
                    let inventory = USBInventory.parse(try await ADB.run(["devices", "-l"]))
                    guard token == self.generation else { return }
                    self.usbTablets = inventory
                    guard let device = USBInventory.choose(inventory, preferred: self.selectedUSB) else {
                        self.busy = false; self.phase = inventory.isEmpty ? "Tableti bağla" : "Tableti seç"
                        self.detail = "USB veri kablosunu tak. Tablette USB hata ayıklamayı açıp bu Mac’e izin ver."
                        self.showWindow?(); self.exportSnapshot(); return
                    }
                    guard device.authorized else {
                        self.busy = false; self.phase = "Tablet izni bekleniyor"; self.detail = "Tablet ekranındaki USB hata ayıklama isteğini onayla, sonra Kablolu’ya yeniden dokun."
                        self.showWindow?(); self.exportSnapshot(); return
                    }
                    self.selectedUSB = device.id; UserDefaults.standard.set(device.id, forKey: "selected-usb")
                    let installed = (try? await ADB.run(["-s", device.id, "shell", "pm", "path", "dev.tabbridge.android"])) ?? ""
                    guard !installed.isEmpty else {
                        self.busy = false; self.phase = "Tablet uygulamasını kur"; self.detail = "Rehberdeki Tablete kur düğmesine dokun. Bu işlem ilk kurulumda gerekir."
                        self.showWindow?(); self.exportSnapshot(); return
                    }
                    _ = try await ADB.run(["-s", device.id, "shell", "am", "start", "-n", "dev.tabbridge.android/app.opendisplay.android.ui.MainActivity"])
                    credential = try await self.pairOverUSB(device, generation: token)
                    guard token == self.generation, !Task.isCancelled else { return }
                    let port = try await ADB.run(["-s", device.id, "forward", "tcp:0", "tcp:9443"])
                    guard let number = UInt16(port) else { throw NSError(domain: "TabBridge.USB", code: 2) }
                    guard token == self.generation, !Task.isCancelled else {
                        _ = try? await ADB.run(["-s", device.id, "forward", "--remove", "tcp:\(port)"])
                        return
                    }
                    self.forwarded = (device.id, port)
                    endpoint = .hostPort(host: "127.0.0.1", port: NWEndpoint.Port(rawValue: number)!)
                    name = device.name
                } else {
                    guard let device = self.wifiTablets.first(where: { $0.id == self.selectedWiFi }) ?? (self.wifiTablets.count == 1 ? self.wifiTablets.first : nil) else {
                        self.busy = false; self.phase = "Tablet bekleniyor"; self.detail = "Tablette TabBridge’i aç. İki cihaz aynı Wi-Fi ağında olmalı."
                        self.showWindow?(); self.exportSnapshot(); return
                    }
                    self.selectedWiFi = device.id; UserDefaults.standard.set(device.id, forKey: "selected-wifi")
                    credential = try PeerStore.tablet(device.id)
                    endpoint = device.endpoint; name = device.name
                }
                guard token == self.generation, !Task.isCancelled else { return }
                guard let credential else { throw PairingError.notPaired }
                self.deviceName = name
                let sender = MacSender(transport: .tcp(endpoint), name: name, mode: .extend, quality: .best, displaySerial: Self.stableSerial(mode == .usb ? self.selectedUSB : self.selectedWiFi),
                    tcpParametersFactory: { credential.parameters() },
                    connectionPreamble: credential.authenticationFrame)
                self.sender = sender
                sender.onStatus = { [weak self] text in guard let self, token == self.generation else { return }; self.record(text) }
                sender.onHello = { [weak self] info in guard let self, token == self.generation else { return }; self.record("Tablet protokolü: \(info.protocolVersion)") }
                let ended = { [weak self] in
                    guard let self, token == self.generation else { return }; self.stop(); self.phase = "Bağlantı sona erdi"; self.detail = "Yeniden başlatmak için widget’tan bağlantı türüne dokun."; self.exportSnapshot()
                }
                sender.onDisconnected = ended; sender.onPeerSleeping = ended; sender.onPeerClosed = ended; sender.onCaptureStoppedByUser = ended
                self.timeout = Task { [weak self] in
                    try? await Task.sleep(for: .seconds(25))
                    guard !Task.isCancelled, let self, token == self.generation, !self.connected else { return }
                    self.stop(); self.phase = "Bağlantı kurulamadı"; self.detail = "Tablet uygulamasının açık olduğunu ve izinleri kontrol edip tekrar dene."; self.showWindow?(); self.exportSnapshot()
                }
                try await sender.start()
                guard token == self.generation, !Task.isCancelled else { sender.stop(); return }
                self.timeout?.cancel(); self.busy = false; self.connected = true; self.pendingTransport = nil
                self.phase = "İkinci ekran açık"; self.detail = "Pencereleri tablete sürükle. S Pen ile dokunabilir ve destekleyen uygulamalarda çizebilirsin."; self.exportSnapshot()
            } catch {
                guard token == self.generation else { return }
                self.stop(); self.phase = "Bağlanamadı"; self.detail = (error as? PairingError)?.localizedDescription ?? "Tablet uygulamasını ve bağlantı iznini kontrol edip tekrar dene."; self.record(error.localizedDescription); self.showWindow?(); self.exportSnapshot()
            }
        }
    }
    func stop(clearPending: Bool = true) {
        generation += 1; operation?.cancel(); operation = nil; timeout?.cancel(); timeout = nil
        sender?.stop(); sender = nil; connected = false; busy = false
        if clearPending { pendingTransport = nil }
        if let forwarded {
            self.forwarded = nil
            Task { _ = try? await ADB.run(["-s", forwarded.serial, "forward", "--remove", "tcp:\(forwarded.port)"]) }
        }
        phase = "Hazır"; exportSnapshot()
    }
    func installReceiver() {
        guard !busy else { return }
        stop()
        generation += 1; let token = generation
        busy = true
        operation = Task { [weak self] in
            guard let self else { return }
            defer { if token == self.generation { self.busy = false } }
            do {
                let devices = USBInventory.parse(try await ADB.run(["devices", "-l"]))
                guard token == self.generation, !Task.isCancelled else { return }
                self.usbTablets = devices
                guard let device = USBInventory.choose(devices, preferred: self.selectedUSB), device.authorized else {
                    self.detail = "Tableti USB ile bağla ve tabletteki izin isteğini onayla."; return
                }
                guard let apk = Bundle.main.resourceURL?.appendingPathComponent("TabBridge-Android.apk"), FileManager.default.fileExists(atPath: apk.path) else {
                    self.detail = "Tablet kurulum dosyası henüz bu pakette yok."; return
                }
                self.detail = "Tablet uygulaması kuruluyor…"
                _ = try await ADB.run(["-s", device.id, "install", "-r", apk.path], timeout: 90)
                guard token == self.generation, !Task.isCancelled else { return }
                self.selectedUSB = device.id; UserDefaults.standard.set(device.id, forKey: "selected-usb")
                _ = try await ADB.run(["-s", device.id, "shell", "am", "start", "-n", "dev.tabbridge.android/app.opendisplay.android.ui.MainActivity"])
                _ = try await self.pairOverUSB(device, generation: token)
                self.phase = "Kurulum tamamlandı"
                self.detail = "Tablet kuruldu ve bu Mac ile güvenle eşleşti. Kablolu’ya dokun veya aynı Wi-Fi ağında Kablosuz’u seç."
                self.exportSnapshot()
            } catch {
                guard token == self.generation, !Task.isCancelled else { return }
                self.detail = "Kurulum tamamlanamadı. Tablet iznini kontrol et."; self.record(error.localizedDescription)
            }
        }
    }
    /// The inventory must positively identify a physical USB transport before exposing pairing material.
    private func pairOverUSB(_ device: USBDevice, generation token: Int) async throws -> PairedTablet {
        guard token == generation, !Task.isCancelled else { throw CancellationError() }
        let client = try PeerStore.clientId()
        let output = try await ADB.run(["-s", device.id, "shell", "content", "call", "--uri", "content://dev.tabbridge.android.pairing", "--method", "pair", "--arg", client])
        guard token == generation, !Task.isCancelled else { throw CancellationError() }
        let peer = try PairedTablet.fromADB(output, client: client)
        try PeerStore.save(peer)
        selectedWiFi = peer.id; UserDefaults.standard.set(peer.id, forKey: "selected-wifi")
        pairingSummary = "Bu Mac eşleştirildi. Wi-Fi bağlantıları şifreli."
        // Never log the provider response, tokens, or Keychain data.
        record("USB üzerinden güvenli eşleştirme tamamlandı.")
        return peer
    }
    func forgetPairing() {
        stop()
        do {
            try PeerStore.forget(selectedWiFi)
            pairingSummary = "Bu Mac’in eşleşmesi silindi. USB ile yeniden eşleştir."
            detail = "Tabletin de bu Mac’i unutması için tablet ayarlarından Eşleşmiş Mac’leri unut’u seç."
        } catch { detail = error.localizedDescription }
    }
    func exportSnapshot() {
        let snapshot = TabSnapshot(phase: phase, device: deviceName, transport: transport, connected: connected)
        if let lastSnapshot, lastSnapshot.phase == snapshot.phase, lastSnapshot.device == snapshot.device, lastSnapshot.transport == snapshot.transport, lastSnapshot.connected == snapshot.connected { return }
        lastSnapshot = snapshot
        if let data = try? JSONEncoder().encode(snapshot) { UserDefaults.standard.set(data, forKey: "widget-snapshot") }
        WidgetCenter.shared.reloadTimelines(ofKind: "TabBridgeSmall")
    }
    static func stableSerial(_ string: String) -> UInt32 {
        string.utf8.reduce(UInt32(2166136261)) { ($0 ^ UInt32($1)) &* 16777619 }
    }
}
