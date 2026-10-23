// SPDX-License-Identifier: GPL-3.0-only
// Copyright (C) 2026 TabBridge contributors.
import WidgetKit
import SwiftUI

struct TabEntry: TimelineEntry { let date: Date; let snapshot: TabSnapshot }
struct TabProvider: TimelineProvider {
    func placeholder(in context: Context) -> TabEntry { .init(date: Date(), snapshot: .init()) }
    func getSnapshot(in context: Context, completion: @escaping (TabEntry) -> Void) { completion(read()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<TabEntry>) -> Void) { completion(.init(entries: [read()], policy: .never)) }
    private func read() -> TabEntry {
        CFPreferencesAppSynchronize("dev.tabbridge.mac" as CFString)
        let data = CFPreferencesCopyAppValue("widget-snapshot" as CFString, "dev.tabbridge.mac" as CFString) as? Data
        return .init(date: Date(), snapshot: data.flatMap { try? JSONDecoder().decode(TabSnapshot.self, from: $0) } ?? .init())
    }
}
struct TabWidgetView: View {
    let entry: TabEntry
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack { Image(systemName: "display.2").foregroundStyle(.indigo); Text("TabBridge").font(.system(size: 12, weight: .bold)); Spacer(minLength: 0) }
            Text(entry.snapshot.phase).font(.system(size: 11, weight: .medium)).foregroundStyle(entry.snapshot.connected ? .green : .secondary).lineLimit(1)
            HStack(spacing: 8) {
                Link(destination: URL(string: "tabbridge://usb")!) { VStack(spacing: 5) { Image(systemName: "cable.connector").font(.title2); Text("Kablolu").font(.system(size: 10, weight: .semibold)) }.frame(maxWidth: .infinity).padding(.vertical, 8) }
                Link(destination: URL(string: "tabbridge://wifi")!) { VStack(spacing: 5) { Image(systemName: "wifi").font(.title2); Text("Kablosuz").font(.system(size: 10, weight: .semibold)) }.frame(maxWidth: .infinity).padding(.vertical, 8) }
            }.buttonStyle(.bordered).tint(.indigo)
            Text("İkinci ekran · S Pen").font(.system(size: 8)).foregroundStyle(.secondary)
        }.containerBackground(for: .widget) { Color.indigo.opacity(0.06) }
            .widgetURL(URL(string: "tabbridge://setup"))
    }
}
@main struct TabBridgeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "TabBridgeSmall", provider: TabProvider()) { TabWidgetView(entry: $0) }
            .configurationDisplayName("TabBridge").description("Kablolu veya kablosuz ikinci ekranı tek dokunuşla başlat.").supportedFamilies([.systemSmall])
    }
}
