import SwiftUI
import WidgetKit

/// Kalan's home screen widget (Roadmap 31), small and medium.
///
/// Shows only text the app wrote to the shared App Group storage
/// (lib/core/widget/widget_snapshot.dart): one record per day for today
/// and the next 7 days, every amount and date already formatted, amounts
/// already masked where they must be. Nothing here calculates or formats
/// a figure: the timeline puts each day's record at that day's midnight
/// and, after the last one, the prebuilt "Open Kalan for the latest." (no
/// amount). The app reloads the timeline whenever it writes.
enum KalanWidgetConfig {
    /// The one Swift copy of the App Group id; the same text is in the
    /// Dart gateway and both entitlements files (a Dart test compares).
    static let appGroup = "group.app.kalan.mobile"
    static let snapshotKey = "kalan.widget.snapshot"
    static let snapshotVersion = 1
    static let kind = "KalanWidget"

    /// A tap opens the app at home (home_widget reads the "homeWidget"
    /// mark); with the app lock on, the lock screen comes first.
    static let tapURL = URL(string: "kalan://widget?homeWidget")!
}

struct WidgetRowText: Decodable {
    let name: String
    let date: String
    let amount: String
}

struct WidgetDayText: Decodable {
    let y: Int
    let m: Int
    let d: Int
    let state: String
    let title: String
    let number: String
    let numberSmall: String
    let until: String
    let rows: [WidgetRowText]
    let message: String
    let spoken: String
}

struct WidgetSnapshot: Decodable {
    let v: Int
    let mode: String
    let message: String
    let rtl: Bool
    let stale: String
    let days: [WidgetDayText]
}

enum KalanWidgetContent {
    /// Nothing written yet: the surface only.
    case blank
    /// The widget gallery: the widget's description, never an amount.
    case preview
    case message(String)
    case day(WidgetDayText)
}

struct KalanEntry: TimelineEntry {
    let date: Date
    let content: KalanWidgetContent
    let rtl: Bool
}

struct KalanWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> KalanEntry {
        KalanEntry(date: Date(), content: .preview, rtl: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (KalanEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }
        completion(Self.entries(now: Date()).first ?? placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<KalanEntry>) -> Void) {
        // Nothing changes on its own after the last entry: the app reloads.
        completion(Timeline(entries: Self.entries(now: Date()), policy: .never))
    }

    static func load() -> WidgetSnapshot? {
        guard
            let text = UserDefaults(suiteName: KalanWidgetConfig.appGroup)?
                .string(forKey: KalanWidgetConfig.snapshotKey),
            let data = text.data(using: .utf8),
            let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data),
            snapshot.v == KalanWidgetConfig.snapshotVersion
        else { return nil }
        return snapshot
    }

    /// Each remaining day's record from its midnight on (today's from
    /// now), then the stale text from the midnight after the last one.
    /// With no record for today (the app has not run for over a week, or
    /// the clock went back) the stale text shows now.
    static func entries(now: Date) -> [KalanEntry] {
        guard let snapshot = load() else {
            return [KalanEntry(date: now, content: .blank, rtl: false)]
        }
        let rtl = snapshot.rtl
        if snapshot.mode != "days" {
            return [KalanEntry(date: now, content: .message(snapshot.message), rtl: rtl)]
        }
        let calendar = Calendar.current
        var entries: [KalanEntry] = []
        var afterLast: Date?
        for day in snapshot.days {
            guard
                let start = calendar.date(from: DateComponents(year: day.y, month: day.m, day: day.d)),
                let end = calendar.date(byAdding: .day, value: 1, to: start)
            else { continue }
            afterLast = end
            if end <= now { continue }
            entries.append(KalanEntry(date: max(start, now), content: .day(day), rtl: rtl))
        }
        let stale = KalanEntry(date: max(afterLast ?? now, now), content: .message(snapshot.stale), rtl: rtl)
        if let first = entries.first, first.date <= now {
            entries.append(stale)
            return entries
        }
        // No record for today.
        return [KalanEntry(date: now, content: .message(snapshot.stale), rtl: rtl)]
    }
}

struct KalanWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: KalanEntry

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            // The app's language, not the phone's: Arabic mirrors (24).
            .environment(\.layoutDirection, entry.rtl ? .rightToLeft : .leftToRight)
            .widgetURL(KalanWidgetConfig.tapURL)
            // Larger text up to where the rows still fit the medium size.
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .kalanWidgetBackground()
    }

    @ViewBuilder
    private var content: some View {
        switch entry.content {
        case .blank:
            Color.clear
        case .preview:
            message(Text("widget.description"))
        case .message(let text):
            message(Text(verbatim: text))
                .accessibilityLabel(Text(verbatim: text))
        case .day(let day):
            Group {
                if family == .systemMedium {
                    medium(day)
                } else {
                    small(day)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: day.spoken))
        }
    }

    private func message(_ text: Text) -> some View {
        text
            .font(.subheadline)
            .foregroundColor(KalanWidgetColors.text)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Left: accent; a negative period: negative; no income: text.
    private func numberColor(_ day: WidgetDayText) -> Color {
        switch day.state {
        case "left": return KalanWidgetColors.accent
        case "negative": return KalanWidgetColors.negative
        default: return KalanWidgetColors.text
        }
    }

    /// Only the big number may shrink, to 60 % at most; the app already
    /// chose the short form for a very long one (widgetSmallNumberMax).
    private func number(_ text: String, size: CGFloat, day: WidgetDayText) -> some View {
        Text(verbatim: text)
            .font(.system(size: size, weight: .bold))
            .foregroundColor(numberColor(day))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
    }

    private func small(_ day: WidgetDayText) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: day.title)
                .font(.subheadline)
                .foregroundColor(KalanWidgetColors.textMuted)
                .lineLimit(1)
            number(day.numberSmall, size: 30, day: day)
            Text(verbatim: day.until)
                .font(.footnote)
                .foregroundColor(KalanWidgetColors.textMuted)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func medium(_ day: WidgetDayText) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Text(verbatim: day.title)
                    .foregroundColor(KalanWidgetColors.textMuted)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Text(verbatim: day.until)
                    .foregroundColor(KalanWidgetColors.textMuted)
                    .lineLimit(1)
                    .fixedSize()
            }
            .font(.subheadline)
            number(day.number, size: 26, day: day)
            if day.rows.isEmpty {
                Text(verbatim: day.message)
                    .font(.footnote)
                    .foregroundColor(KalanWidgetColors.textMuted)
                    .lineLimit(2)
            }
            ForEach(Array(day.rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    // Names end with an ellipsis; dates and amounts never
                    // shrink or cut.
                    Text(verbatim: row.name)
                        .foregroundColor(KalanWidgetColors.text)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 0)
                    Text(verbatim: row.date)
                        .foregroundColor(KalanWidgetColors.textMuted)
                        .lineLimit(1)
                        .fixedSize()
                    Text(verbatim: row.amount)
                        .foregroundColor(KalanWidgetColors.text)
                        .lineLimit(1)
                        .fixedSize()
                }
                .font(.footnote)
            }
            Spacer(minLength: 0)
        }
    }
}

private extension View {
    /// The surface token, flat; the system's own margins and corners.
    @ViewBuilder
    func kalanWidgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) { KalanWidgetColors.surface }
        } else {
            padding(16).background(KalanWidgetColors.surface)
        }
    }
}

@main
struct KalanWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: KalanWidgetConfig.kind, provider: KalanWidgetProvider()) { entry in
            KalanWidgetView(entry: entry)
        }
        .configurationDisplayName(Text("widget.name"))
        .description(Text("widget.description"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
