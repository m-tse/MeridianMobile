import SwiftUI
import UIKit

struct DayNightBar: View {
    let timeZone: TimeZone
    let selectedDate: Date
    @Binding var hourOffset: Double
    @State private var lastTapTime: Date = .distantPast

    private let markerSize: CGFloat = 24
    private let totalHeight: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Tick marks - every 15 minutes (96 ticks)
                ForEach(0..<97, id: \.self) { tick in
                    let hour = Double(tick) / 4.0
                    let x = CGFloat(tick) / 96.0 * geo.size.width
                    let isHourMark = tick % 4 == 0
                    let isMajorMark = tick % 24 == 0 // 0, 6, 12, 18, 24

                    let tickH: CGFloat = isMajorMark ? 14 : (isHourMark ? 9 : 5)
                    let tickW: CGFloat = 1.0
                    let isDaytime = hour >= 6 && hour <= 18
                    let tickColor = isDaytime ? Color.orange : Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.4, alpha: 1) : .black })

                    Rectangle()
                        .fill(tickColor)
                        .frame(width: tickW, height: tickH)
                        .position(x: x, y: totalHeight / 2)
                }

                // Draggable marker circle
                let clampedX = markerPosition(in: geo.size.width)
                ZStack {
                    Circle()
                        .fill(Color(white: 0.92))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    HStack(spacing: 1) {
                        Image(systemName: "chevron.left")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(Color(white: 0.35))
                }
                .frame(width: markerSize, height: markerSize)
                .position(x: clampedX, y: totalHeight / 2)
            }
            .frame(height: totalHeight)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let fraction = max(0, min(value.location.x / geo.size.width, 1.0))
                        let targetHour = fraction * 24.0

                        // Get the currently displayed date's start-of-day in this timezone
                        var cal = Calendar.current
                        cal.timeZone = timeZone
                        let dayStart = cal.startOfDay(for: selectedDate)

                        // Build target date: same day, but at the dragged hour
                        let targetDate = dayStart.addingTimeInterval(targetHour * 3600)

                        let now = Date()
                        let diff = targetDate.timeIntervalSince(now) / 3600.0
                        hourOffset = (diff * 60).rounded() / 60 // snap to 1 minute
                    }
                    .onEnded { value in
                        let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                        if distance < 5 {
                            let now = Date()
                            if now.timeIntervalSince(lastTapTime) < 0.3 {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    hourOffset = 0
                                }
                                lastTapTime = .distantPast
                            } else {
                                lastTapTime = now
                            }
                        }
                    }
            )
        }
        .frame(height: totalHeight)
    }

    private func markerPosition(in width: CGFloat) -> CGFloat {
        var cal = Calendar.current
        cal.timeZone = timeZone
        let hour = cal.component(.hour, from: selectedDate)
        let minute = cal.component(.minute, from: selectedDate)
        let fraction = (Double(hour) + Double(minute) / 60.0) / 24.0
        return fraction * width
    }
}
