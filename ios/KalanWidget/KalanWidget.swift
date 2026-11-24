import SwiftUI
import WidgetKit

/// Kalan's home screen widget (Roadmap 31), small and medium, and, on
/// iOS 16 and later, its Lock Screen widget (Roadmap 32): inline,
/// rectangular and circular, drawn by the system in one tint (no palette
/// colour there), in the phone's own font.
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

    /// The Lock Screen widget without Pro opens the Pro screen (the app
    /// reads the path; widgetProPath in the Dart gateway).
    static let proURL = URL(string: "kalan://widget/pro?homeWidget")!
}

/// One day's Lock Screen text (Roadmap 32); only written with Pro. Never
/// a payment amount; `left` is empty unless every privacy choice allows it.
struct LockDayText: Decodable {
    let line: String
    let centerKind: String
    let center: String
    let count: String
    let left: String
}

/// The Lock Screen widget's day-independent text (Roadmap 32).
struct LockText: Decodable {
    let pro: Bool
    let title: String
    let gateInline: String
    let gate: String
    let open: String
    let stale: String
    let message: String
    let messageInline: String
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
    let lock: LockDayText?
}

struct WidgetSnapshot: Decodable {
    let v: Int
    let mode: String
    let message: String
    let rtl: Bool
    let stale: String
    let days: [WidgetDayText]
    let lock: LockText?
}

enum KalanWidgetContent {
    /// Nothing written yet: the surface only.
    case blank
    /// The widget gallery: the widget's description, never an amount.
    case preview
    /// Setup or "No payments yet.": the same on any date.
    case message(String)
    /// No record for today: "Open Kalan for the latest."
    case stale(String)
    case day(WidgetDayText)
}

struct KalanEntry: TimelineEntry {
    let date: Date
    let content: KalanWidgetContent
    let rtl: Bool
    /// The Lock Screen widget's own text (nil: nothing written yet).
    var lockText: LockText? = nil
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
        let lock = snapshot.lock
        if snapshot.mode != "days" {
            return [KalanEntry(date: now, content: .message(snapshot.message), rtl: rtl, lockText: lock)]
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
            entries.append(KalanEntry(date: max(start, now), content: .day(day), rtl: rtl, lockText: lock))
        }
        let stale = KalanEntry(date: max(afterLast ?? now, now), content: .stale(snapshot.stale), rtl: rtl, lockText: lock)
        if let first = entries.first, first.date <= now {
            entries.append(stale)
            return entries
        }
        // No record for today.
        return [KalanEntry(date: now, content: .stale(snapshot.stale), rtl: rtl, lockText: lock)]
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
        case .message(let text), .stale(let text):
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

    /// The Lock Screen draws no surface of its own: nothing behind the
    /// inline and rectangular widgets, the system's round background
    /// behind the circular one.
    @available(iOSApplicationExtension 16.0, *)
    @ViewBuilder
    func lockScreenBackground(circular: Bool) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(for: .widget) {
                if circular {
                    AccessoryWidgetBackground()
                }
            }
        } else if circular {
            background(AccessoryWidgetBackground())
        } else {
            self
        }
    }
}

/// What the Lock Screen widget shows (Roadmap 32), in this order: without
/// Pro only the calm Pro note (whatever the date); then the stale or
/// setup text; then the day's line. Every word comes from the app.
@available(iOSApplicationExtension 16.0, *)
struct KalanLockScreenView: View {
    @Environment(\.widgetFamily) private var family
    let entry: KalanEntry

    /// Only a written "not Pro" opens the Pro screen: an older snapshot
    /// without Lock Screen text opens home.
    private var gated: Bool { entry.lockText?.pro == false }

    var body: some View {
        content
            .environment(\.layoutDirection, entry.rtl ? .rightToLeft : .leftToRight)
            .widgetURL(gated ? KalanWidgetConfig.proURL : KalanWidgetConfig.tapURL)
            // Larger text up to where "Left …" still fits on one line of
            // the narrowest rectangular widget (iPhone mini and SE).
            .dynamicTypeSize(...DynamicTypeSize.xLarge)
            .lockScreenBackground(circular: family == .accessoryCircular)
    }

    @ViewBuilder
    private var content: some View {
        switch (entry.content, entry.lockText) {
        case (.blank, _), (.preview, _), (_, nil):
            // Nothing written yet, or the gallery: the name and the mark.
            if family == .accessoryCircular {
                logo.accessibilityLabel(Text("widget.name"))
            } else {
                Text("widget.name")
            }
        case (_, .some(let lock)) where !lock.pro:
            switch family {
            case .accessoryCircular:
                logo.accessibilityLabel(Text(verbatim: lock.gate))
            case .accessoryInline:
                Text(verbatim: lock.gateInline)
            default:
                noteText(lock.gate)
            }
        case (.stale, .some(let lock)):
            notice(lock: lock, inline: lock.open, text: lock.stale)
        case (.message, .some(let lock)):
            notice(lock: lock, inline: lock.messageInline, text: lock.message)
        case (.day(let day), .some(let lock)):
            if let text = day.lock {
                dayView(lock: lock, day: text)
            } else {
                notice(lock: lock, inline: lock.open, text: lock.stale)
            }
        }
    }

    /// Stale, setup or no payments: the mark in the circle.
    @ViewBuilder
    private func notice(lock: LockText, inline: String, text: String) -> some View {
        switch family {
        case .accessoryCircular:
            logo.accessibilityLabel(Text(verbatim: text))
        case .accessoryInline:
            Text(verbatim: inline)
        default:
            noteText(text)
        }
    }

    /// A whole sentence on the rectangular widget (the Pro note, stale,
    /// setup): up to three lines, never cut.
    private func noteText(_ text: String) -> some View {
        Text(verbatim: text)
            .font(.subheadline)
            .lineLimit(3)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func dayView(lock: LockText, day: LockDayText) -> some View {
        switch family {
        case .accessoryCircular:
            circular(day)
        case .accessoryInline:
            Text(verbatim: day.line)
        default:
            rectangular(title: lock.title, line: day.line, left: day.left)
        }
    }

    /// "Kalan", the line, and "Left …" only when the app wrote it.
    private func rectangular(title: String, line: String, left: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: title)
                .font(.headline)
                .lineLimit(1)
            Text(verbatim: line)
                .font(.subheadline)
                .lineLimit(left.isEmpty ? 2 : 1)
            if !left.isEmpty {
                Text(verbatim: left)
                    .font(.subheadline)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// The number of days or a short word, the count below; only here may
    /// text shrink to fit. Read as the whole line.
    @ViewBuilder
    private func circular(_ day: LockDayText) -> some View {
        if day.centerKind == "logo" {
            logo.accessibilityLabel(Text(verbatim: day.line))
        } else {
            VStack(spacing: 0) {
                Text(verbatim: day.center)
                    .font(centerFont(day))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Text(verbatim: day.count)
                    .font(.system(.caption2))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(6)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: day.line))
        }
    }

    private func centerFont(_ day: LockDayText) -> Font {
        day.centerKind == "number"
            ? .system(.title2, design: .rounded, weight: .semibold)
            : .system(.footnote, weight: .semibold)
    }

    private var logo: some View {
        KalanMark()
            .aspectRatio(941.0 / 1023.0, contentMode: .fit)
            .padding(12)
            // One element, so the label set by each caller is read.
            .accessibilityElement(children: .ignore)
    }
}

/// The Kalan mark (assets/brand/kalan_mark.svg) as one shape, so the
/// system tints it like any Lock Screen glyph; no image file and no colour.
struct KalanMark: Shape {
    func path(in rect: CGRect) -> Path {
        // The mark's own box in the 2048-unit drawing.
        let scale = min(rect.width / 941, rect.height / 1023)
        let dx = rect.midX - 941 * scale / 2 - 553 * scale
        let dy = rect.midY - 1023 * scale / 2 - 512 * scale
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x * scale + dx, y: y * scale + dy)
        }
        var path = Path()
        path.move(to: p(587, 512))
        path.addLine(to: p(784, 512))
        path.addQuadCurve(to: p(818, 546), control: p(818, 512))
        path.addLine(to: p(818, 1501))
        path.addQuadCurve(to: p(784, 1535), control: p(818, 1535))
        path.addLine(to: p(587, 1535))
        path.addQuadCurve(to: p(553, 1501), control: p(553, 1535))
        path.addLine(to: p(553, 546))
        path.addQuadCurve(to: p(587, 512), control: p(553, 512))
        path.closeSubpath()
        path.move(to: p(802.6, 953.6))
        path.addLine(to: p(1172.4, 537.4))
        path.addQuadCurve(to: p(1229, 512), control: p(1195, 512))
        path.addLine(to: p(1459, 512))
        path.addQuadCurve(to: p(1470.3, 537.3), control: p(1493, 512))
        path.addLine(to: p(802.7, 1283.7))
        path.addQuadCurve(to: p(780, 1275), control: p(780, 1309))
        path.addLine(to: p(780, 1013))
        path.addQuadCurve(to: p(802.6, 953.6), control: p(780, 979))
        path.closeSubpath()
        path.move(to: p(1140, 1059))
        path.addLine(to: p(1178, 1104))
        path.addQuadCurve(to: p(1176.6, 1154.7), control: p(1200, 1130))
        path.addLine(to: p(1060.4, 1277.3))
        path.addQuadCurve(to: p(1015, 1276), control: p(1037, 1302))
        path.addLine(to: p(977, 1231))
        path.addQuadCurve(to: p(978.4, 1180.3), control: p(955, 1205))
        path.addLine(to: p(1094.6, 1057.7))
        path.addQuadCurve(to: p(1140, 1059), control: p(1118, 1033))
        path.closeSubpath()
        path.move(to: p(1268, 1211))
        path.addLine(to: p(1306, 1256))
        path.addQuadCurve(to: p(1304.6, 1306.7), control: p(1328, 1282))
        path.addLine(to: p(1188.4, 1429.3))
        path.addQuadCurve(to: p(1143, 1428), control: p(1165, 1454))
        path.addLine(to: p(1105, 1383))
        path.addQuadCurve(to: p(1106.4, 1332.3), control: p(1083, 1357))
        path.addLine(to: p(1222.6, 1209.7))
        path.addQuadCurve(to: p(1268, 1211), control: p(1246, 1185))
        path.closeSubpath()
        path.move(to: p(1395, 1363))
        path.addLine(to: p(1472, 1454))
        path.addQuadCurve(to: p(1482, 1507.5), control: p(1494, 1480))
        path.addLine(to: p(1482, 1507.5))
        path.addQuadCurve(to: p(1436, 1535), control: p(1470, 1535))
        path.addLine(to: p(1249, 1535))
        path.addQuadCurve(to: p(1236.2, 1508.4), control: p(1215, 1535))
        path.addLine(to: p(1351.8, 1363.6))
        path.addQuadCurve(to: p(1395, 1363), control: p(1373, 1337))
        path.closeSubpath()
        return path
    }
}

/// The home screen sizes, and the Lock Screen ones on iOS 16 and later.
private var kalanFamilies: [WidgetFamily] {
    if #available(iOSApplicationExtension 16.0, *) {
        return [.systemSmall, .systemMedium, .accessoryInline, .accessoryRectangular, .accessoryCircular]
    }
    return [.systemSmall, .systemMedium]
}

/// One widget kind for both screens, so the app's one reload redraws them
/// together; each family picks its own view.
struct KalanEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: KalanEntry

    @available(iOSApplicationExtension 16.0, *)
    private static var lockScreenFamilies: [WidgetFamily] {
        [.accessoryInline, .accessoryRectangular, .accessoryCircular]
    }

    var body: some View {
        if #available(iOSApplicationExtension 16.0, *) {
            if Self.lockScreenFamilies.contains(family) {
                KalanLockScreenView(entry: entry)
            } else {
                KalanWidgetView(entry: entry)
            }
        } else {
            KalanWidgetView(entry: entry)
        }
    }
}

@main
struct KalanWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: KalanWidgetConfig.kind, provider: KalanWidgetProvider()) { entry in
            KalanEntryView(entry: entry)
        }
        .configurationDisplayName(Text("widget.name"))
        .description(Text("widget.description"))
        .supportedFamilies(kalanFamilies)
    }
}
