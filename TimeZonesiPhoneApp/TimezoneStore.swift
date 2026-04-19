import SwiftUI
import UIKit

struct WorldTimezone: Identifiable, Codable, Equatable {
    let identifier: String
    var label: String
    var backgroundColorHex: String?
    var id: String { identifier }

    var timeZone: TimeZone {
        TimeZone(identifier: identifier) ?? .current
    }

    var backgroundColor: Color? {
        guard let hex = backgroundColorHex else { return nil }
        return Color(hex: hex)
    }
}

extension Color {
    init?(hex: String) {
        var s = hex
        if s.hasPrefix("#") { s.removeFirst() }
        guard let val = UInt64(s, radix: 16) else { return nil }
        switch s.count {
        case 6:
            let r = Double((val >> 16) & 0xff) / 255
            let g = Double((val >> 8) & 0xff) / 255
            let b = Double(val & 0xff) / 255
            self = Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
        case 8:
            let r = Double((val >> 24) & 0xff) / 255
            let g = Double((val >> 16) & 0xff) / 255
            let b = Double((val >> 8) & 0xff) / 255
            let a = Double(val & 0xff) / 255
            self = Color(.sRGB, red: r, green: g, blue: b, opacity: a)
        default:
            return nil
        }
    }

    func toHexString() -> String? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let ri = Int((r * 255).rounded())
        let gi = Int((g * 255).rounded())
        let bi = Int((b * 255).rounded())
        let ai = Int((a * 255).rounded())
        return String(format: "#%02X%02X%02X%02X", ri, gi, bi, ai)
    }
}

class TimezoneStore: ObservableObject {
    @Published var timezones: [WorldTimezone] = []
    @Published var hourOffset: Double = 0
    @Published var referenceTimezoneId: String = TimeZone.current.identifier
    @Published var use24Hour: Bool {
        didSet { UserDefaults.standard.set(use24Hour, forKey: "worldclock_use24Hour") }
    }
    @Published var referenceHighlightHex: String? = UserDefaults.standard.string(forKey: "worldclock_referenceHighlight") {
        didSet {
            if let h = referenceHighlightHex {
                UserDefaults.standard.set(h, forKey: "worldclock_referenceHighlight")
            } else {
                UserDefaults.standard.removeObject(forKey: "worldclock_referenceHighlight")
            }
        }
    }

    var referenceHighlightColor: Color {
        if let hex = referenceHighlightHex, let c = Color(hex: hex) { return c }
        return Color.accentColor.opacity(0.12)
    }

    var referenceTimeZone: TimeZone {
        TimeZone(identifier: referenceTimezoneId) ?? .current
    }

    init() {
        self.use24Hour = UserDefaults.standard.object(forKey: "worldclock_use24Hour") as? Bool ?? true
        if let data = UserDefaults.standard.data(forKey: "worldclock_timezones"),
           let saved = try? JSONDecoder().decode([WorldTimezone].self, from: data) {
            timezones = saved
        } else {
            timezones = Self.defaultTimezones
        }
        ensureLocalTimezone()
    }

    func ensureLocalTimezone() {
        let localId = TimeZone.current.identifier
        if !timezones.contains(where: { $0.identifier == localId }) {
            let label: String
            if let match = AddTimezoneView.commonTimezones.first(where: { $0.0 == localId }) {
                label = match.1
            } else {
                label = localId.components(separatedBy: "/").last?.replacingOccurrences(of: "_", with: " ") ?? localId
            }
            timezones.append(WorldTimezone(identifier: localId, label: label))
            save()
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(timezones) {
            UserDefaults.standard.set(data, forKey: "worldclock_timezones")
        }
    }

    func add(_ tz: WorldTimezone) {
        guard !timezones.contains(where: { $0.identifier == tz.identifier }) else { return }
        timezones.append(tz)
        save()
    }

    func remove(_ tz: WorldTimezone) {
        timezones.removeAll { $0.identifier == tz.identifier }
        save()
    }

    func rename(_ tz: WorldTimezone, to newLabel: String) {
        if let idx = timezones.firstIndex(where: { $0.identifier == tz.identifier }) {
            timezones[idx].label = newLabel
            save()
        }
    }

    func setBackgroundColor(_ tz: WorldTimezone, hex: String?) {
        if let idx = timezones.firstIndex(where: { $0.identifier == tz.identifier }) {
            timezones[idx].backgroundColorHex = hex
            save()
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        timezones.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func sortedTimezones(for date: Date) -> [WorldTimezone] {
        timezones.sorted { a, b in
            a.timeZone.secondsFromGMT(for: date) < b.timeZone.secondsFromGMT(for: date)
        }
    }

    static let defaultTimezones: [WorldTimezone] = [
        WorldTimezone(identifier: "America/Los_Angeles", label: "Los Angeles, US"),
        WorldTimezone(identifier: "America/New_York", label: "New York, US"),
        WorldTimezone(identifier: "Europe/London", label: "London, UK"),
        WorldTimezone(identifier: "Asia/Tokyo", label: "Tokyo, Japan"),
        WorldTimezone(identifier: "Australia/Sydney", label: "Sydney, Australia"),
    ]
}
