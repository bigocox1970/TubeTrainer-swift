import Foundation

enum TTFormat {

    /// Weight without trailing ".0", with unit label. e.g. "32.5 kg", "80 kg".
    static func weight(_ value: Double, unit: WeightUnit) -> String {
        "\(number(value)) \(unit.label)"
    }

    /// Locale-aware decimal: integers show clean, fractions up to 2 dp using the
    /// user's decimal separator (e.g. "12,5" in es/de, "12.5" in en). No grouping —
    /// these are gym weights, not large numbers.
    private static let decimal: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        f.usesGroupingSeparator = false
        return f
    }()

    static func number(_ value: Double) -> String {
        decimal.string(from: NSNumber(value: value)) ?? String(value)
    }

    /// "80 × 8"
    static func weightReps(_ weight: Double, reps: Int) -> String {
        "\(number(weight)) × \(reps)"
    }

    /// Elapsed clock "MM:SS" or "H:MM:SS".
    static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, sec)
        }
        return String(format: "%d:%02d", m, sec)
    }

    /// Duration in human words, localized: "54 min", "1h 12m" (units follow locale).
    private static let durationFormatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.hour, .minute]
        f.unitsStyle = .abbreviated
        f.zeroFormattingBehavior = .dropAll
        return f
    }()

    static func duration(_ seconds: Int) -> String {
        // Floor at one minute so a short session never renders empty.
        durationFormatter.string(from: TimeInterval(max(60, seconds))) ?? ""
    }

    /// Rest presets label "1:30", "2:00".
    static func rest(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m == 0 { return "\(s)s" }
        if s == 0 { return "\(m):00" }
        return String(format: "%d:%02d", m, s)
    }

    private static let relative: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .full
        return f
    }()

    /// "Last trained Monday" style — weekday within a week, else relative. All locale-aware.
    static func lastTrained(_ date: Date, now: Date = .now) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return TTLocalized("Today") }
        if cal.isDateInYesterday(date) { return TTLocalized("Yesterday") }
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: cal.startOfDay(for: now)).day ?? 0
        if days < 7 {
            return date.formatted(.dateTime.weekday(.wide))   // localized weekday name
        }
        return relative.localizedString(for: date, relativeTo: now)
    }

    static func mediumDate(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .omitted)     // locale medium date
    }

    /// Localized weekday + day + month + time, e.g. "Mon 8 Sep · 14:30" / "lun 8 sept, 14:30".
    /// Word order and 12/24-hour follow the user's locale.
    static func dayAndTime(_ date: Date) -> String {
        let day = date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        let time = date.formatted(date: .omitted, time: .shortened)
        return "\(day) · \(time)"
    }
}

// MARK: - 1RM estimation

enum OneRepMax {
    /// Epley formula. Documented, consistent, clearly an *estimate*.
    /// 1RM = weight × (1 + reps / 30)
    static func epley(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return 0 }
        if reps == 1 { return weight }
        return weight * (1.0 + Double(reps) / 30.0)
    }
}
