// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TabBridge contributors.
import SwiftUI
import AppKit

struct TabMainView: View {
    @Bindable var model: TabModel
    @State private var confirmingForget = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 14) {
                    Image(systemName: "display.2").font(.system(size: 29)).foregroundStyle(.white)
                        .frame(width: 62, height: 62).background(.indigo.gradient, in: RoundedRectangle(cornerRadius: 17))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("TabBridge").font(.system(size: 27, weight: .bold))
                        Text("Galaxy Tab, Mac’in ikinci ekranı.").foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                VStack(alignment: .leading, spacing: 10) {
                    Label(model.phase, systemImage: model.connected ? "checkmark.circle.fill" : "display")
                        .font(.headline).foregroundStyle(model.connected ? .green : .primary)
                    Text(model.detail).font(.callout).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 12) {
                        connectButton(.usb); connectButton(.wifi)
                    }
                    if model.busy { ProgressView().controlSize(.small) }
                    if model.busy || model.connected { Button("Bağlantıyı kes") { model.stop() } }
                }.tabCard()
                if !model.screenPermission || !model.inputPermission {
                    VStack(alignment: .leading, spacing: 13) {
                        Text("1 · Mac izinlerini tamamla").font(.headline)
                        permission("Ekran kaydı", detail: "Mac’in ikinci ekran görüntüsünü tablete aktarır.", granted: model.screenPermission, action: model.grantScreen)
                        permission("Erişilebilirlik", detail: "S Pen ve tablet dokunuşlarını Mac’e iletir.", granted: model.inputPermission, action: model.grantInput)
                        Text("İzin verdikten sonra bu pencereye dön. macOS isterse uygulamayı bir kez kapatıp yeniden aç.")
                            .font(.caption).foregroundStyle(.secondary)
                    }.tabCard()
                }
                VStack(alignment: .leading, spacing: 13) {
                    Text("2 · Bir kez kur ve güvenle eşleştir").font(.headline)
                    Text("Kablolu").font(.subheadline.bold())
                    Text("USB veri kablosunu bağla. Tablette Ayarlar → Tablet hakkında → Yazılım bilgileri → Yapım numarası’na 7 kez dokun. Geliştirici seçeneklerinden USB hata ayıklamayı aç ve bu Mac’e izin ver.")
                        .font(.callout).foregroundStyle(.secondary)
                    HStack {
                        Button("Tableti bul") { model.refreshUSB() }
                        Button("Kur ve eşleştir") { model.installReceiver() }.disabled(model.busy)
                    }
                    if !model.usbTablets.isEmpty {
                        Picker("USB tablet", selection: $model.selectedUSB) {
                            Text("Seç").tag("")
                            ForEach(model.usbTablets) { device in Text(device.name + (device.authorized ? "" : " · izin bekliyor")).tag(device.id) }
                        }
                    }
                    Label(model.pairingSummary, systemImage: "lock.shield").font(.caption).foregroundStyle(.secondary)
                    Text("Kablosuz").font(.subheadline.bold())
                    Text("İlk USB eşleştirmesinden sonra tablette TabBridge’i aç; aynı Wi-Fi ağında Kablosuz’a dokun. Kabloyu çıkarabilirsin. Görüntü, S Pen ve imleç verileri TLS ile şifrelenir.")
                        .font(.callout).foregroundStyle(.secondary)
                    if !model.wifiTablets.isEmpty {
                        Picker("Wi-Fi tablet", selection: $model.selectedWiFi) {
                            Text("Seç").tag("")
                            ForEach(model.wifiTablets) { tablet in Text(tablet.name).tag(tablet.id) }
                        }
                    }
                }.tabCard()
                VStack(alignment: .leading, spacing: 10) {
                    Text("3 · Widget’tan tek dokunuşla aç").font(.headline)
                    Text("Masaüstüne sağ tıkla → Widget’ları Düzenle → TabBridge. Küçük widget’ı ekle. Sonraki kullanımlarda Kablolu veya Kablosuz’a dokunman yeterli.")
                        .font(.callout).foregroundStyle(.secondary)
                    Text("Pencereyi Mac ekranının kenarından tablete sürükle. S Pen ile tıkla, sürükle ve kalem destekleyen uygulamalarda çiz. İki parmakla kaydırabilirsin.")
                        .font(.callout).foregroundStyle(.secondary)
                    Button("Ekranların konumunu ayarla") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension") { NSWorkspace.shared.open(url) }
                    }
                }.tabCard()
                DisclosureGroup("Bağlantı ayrıntıları") {
                    Button("Bu Mac’in eşleşmesini unut") { confirmingForget = true }
                        .confirmationDialog("Bu Mac’in eşleştirmesi silinsin mi?", isPresented: $confirmingForget) {
                            Button("Eşleşmeyi unut", role: .destructive) { model.forgetPairing() }
                        }
                    Text(model.logs.suffix(30).joined(separator: "\n")).font(.system(size: 10, design: .monospaced))
                        .textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                }
                Text("Deneysel geliştirme sürümü · OpenDisplay temel alınmıştır · GPL-3.0 · Garanti verilmez.")
                    .font(.caption2).foregroundStyle(.tertiary)
            }.padding(24)
        }.frame(minWidth: 540, minHeight: 680).tint(.indigo)
    }
    private func connectButton(_ mode: TabTransport) -> some View {
        Button { model.connect(mode) } label: { Label(mode.title, systemImage: mode.symbol).frame(maxWidth: .infinity).padding(.vertical, 7) }
            .buttonStyle(.borderedProminent)
            .tint(model.connected && model.transport == mode ? .green : .indigo)
            .accessibilityHint("Galaxy Tab üzerinde genişletilmiş masaüstünü aç")
    }
    private func permission(_ name: String, detail: String, granted: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) { Text(name).font(.callout.bold()); Text(detail).font(.caption).foregroundStyle(.secondary) }
            Spacer()
            if granted { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
            else { Button("İzin ver", action: action) }
        }
    }
}
private extension View {
    func tabCard() -> some View {
        padding(17).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06)))
    }
}
