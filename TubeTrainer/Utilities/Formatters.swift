import Foundation

enum TTFormat {

    /// Weight without trailing ".0", with unit label. e.g. "32.5 kg", "80 kg".
    static func weight(_ value: Double, unit: WeightUnit) -> String {
        "\(number(value)) \(unit.label)"
    }

    static func number(_ value: Double) -> String {
        if value == value.rounded() {
            return String(Int(value))
        }
        return String(format: "%.2f", value)
            .replacingOccurrences(of: "0$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\.$", with: "", options: .regularExpression)
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

    /// Duration in human words: "54 min", "1 hr 12 min".
    static func duration(_ seconds: Int) -> String {
        let m = max(0, seconds) / 60
        if m < 60 { return "\(m) min" }
        return "\(m / 60) hr \(m % 60) min"
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

    /// "Last trained Monday" style — weekday within a week, else relative.
    static func lastTrained(_ date: Date, now: Date = .now) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: date), to: cal.startOfDay(for: now)).day ?? 0
        if days < 7 {
            let f = DateFormatter()
            f.dateFormat = "EEEE"
            return f.string(from: date)
        }
        return relative.localizedString(for: date, relativeTo: now)
    }

    static func mediumDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }

    static func dayAndTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE d MMM · HH:mm"
        return f.string(from: date)
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
