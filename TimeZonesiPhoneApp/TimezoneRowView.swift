import SwiftUI

struct TimezoneRowView: View {
    let timezone: WorldTimezone
    let selectedDate: Date
    let localTimeZone: TimeZone
    @Binding var hourOffset: Double
    var isHighlighted: Bool = false
    var use24Hour: Bool = true
    var onDateTap: (() -> Void)? = nil
    @State private var colonVisible = true
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(timezone.label)
                            .font(.system(size: 20, weight: isHighlighted ? .bold : .medium))
                    }
                    HStack(spacing: 8) {
                        Text(abbreviation)
                            .font(.system(size: 14))
                            .foregroundColor(colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.3))
                        Text(formattedDate)
                            .font(.system(size: 14))
                            .foregroundColor(dateColor)
                            .underline(color: dateColor.opacity(0.5))
                            .onTapGesture {
                                onDateTap?()
                            }
                        if hourDelta != 0 {
                            Text(hourDeltaLabel)
                                .font(.system(size: 14))
                                .foregroundColor(hourDelta > 0 ? positiveColor : negativeColor)
                        }
                    }
                }
                Spacer()
                HStack(spacing: 0) {
                    Text(timeHour)
                        .font(.system(size: 38, weight: .medium, design: .rounded))
                        .monospacedDigit()
                    Text(":")
                        .font(.system(size: 38, weight: .medium, design: .rounded))
                        .monospacedDigit()
                        .opacity(colonVisible ? 1 : 0.15)
                        .offset(y: -1.5)
                    Text(timeMinuteAndPeriod)
                        .font(.system(size: 38, weight: .medium, design: .rounded))
                        .monospacedDigit()
                }
            }

            DayNightBar(timeZone: timezone.timeZone, selectedDate: selectedDate, hourOffset: $hourOffset)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
        .background(isHighlighted ? Color.accentColor.opacity(0.12) : Color.clear)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                colonVisible = false
            }
        }
    }

    private var hourInTimezone: Int {
        var cal = Calendar.current
        cal.timeZone = timezone.timeZone
        return cal.component(.hour, from: selectedDate)
    }

    private var isDaytime: Bool {
        let hour = hourInTimezone
        return hour >= 6 && hour < 20
    }

    private var timeHour: String {
        let fmt = DateFormatter()
        fmt.dateFormat = use24Hour ? "HH" : "h"
        fmt.timeZone = timezone.timeZone
        return fmt.string(from: selectedDate)
    }

    private var timeMinuteAndPeriod: String {
        let fmt = DateFormatter()
        if use24Hour {
            fmt.dateFormat = "mm"
        } else {
            fmt.dateFormat = "mm a"
        }
        fmt.timeZone = timezone.timeZone
        return fmt.string(from: selectedDate)
    }

    private var formattedTime: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        fmt.timeZone = timezone.timeZone
        return fmt.string(from: selectedDate)
    }

    private var abbreviation: String {
        let offset = timezone.timeZone.secondsFromGMT(for: selectedDate)
        let h = offset / 3600
        let m = abs(offset % 3600) / 60
        if m == 0 {
            return "GMT\(h >= 0 ? "+" : "")\(h)"
        } else {
            return String(format: "GMT%+d:%02d", h, m)
        }
    }

    private var formattedDate: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE MMM d"
        fmt.timeZone = timezone.timeZone
        return fmt.string(from: selectedDate)
    }

    private var positiveColor: Color {
        colorScheme == .dark ? Color(red: 0.2, green: 0.8, blue: 0.2) : Color(red: 0.0, green: 0.47, blue: 0.0)
    }

    private var negativeColor: Color {
        colorScheme == .dark ? Color(red: 1.0, green: 0.35, blue: 0.35) : Color(red: 0.78, green: 0.0, blue: 0.0)
    }

    private var dateColor: Color {
        let diff = dayOffset
        if diff < 0 { return negativeColor }
        if diff > 0 { return positiveColor }
        return colorScheme == .dark ? Color(white: 0.6) : Color(white: 0.3)
    }

    private var dayOffset: Int {
        var localCal = Calendar.current
        localCal.timeZone = localTimeZone
        var remoteCal = Calendar.current
        remoteCal.timeZone = timezone.timeZone

        let localComps = localCal.dateComponents([.year, .month, .day], from: selectedDate)
        let remoteComps = remoteCal.dateComponents([.year, .month, .day], from: selectedDate)

        let localDate = localCal.date(from: localComps)!
        let remoteDate = localCal.date(from: remoteComps)!

        return localCal.dateComponents([.day], from: localDate, to: remoteDate).day ?? 0
    }

    private var hourDelta: Int {
        let localOffset = localTimeZone.secondsFromGMT(for: selectedDate)
        let remoteOffset = timezone.timeZone.secondsFromGMT(for: selectedDate)
        return (remoteOffset - localOffset) / 3600
    }

    private var hourDeltaLabel: String {
        let d = hourDelta
        return d > 0 ? "+\(d)h" : "\(d)h"
    }

    private var isDifferentDay: Bool {
        var localCal = Calendar.current
        localCal.timeZone = localTimeZone
        var remoteCal = Calendar.current
        remoteCal.timeZone = timezone.timeZone

        let localDay = localCal.dateComponents([.year, .month, .day], from: selectedDate)
        let remoteDay = remoteCal.dateComponents([.year, .month, .day], from: selectedDate)

        return localDay.year != remoteDay.year ||
               localDay.month != remoteDay.month ||
               localDay.day != remoteDay.day
    }
}
