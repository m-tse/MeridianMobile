import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: TimezoneStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var now = Date()
    @State private var showingAdd = false
    @State private var showingDatePicker = false
    @State private var pickerDate = Date()
    @State private var pickerTimeZone = TimeZone.current
    @State private var renamingTimezone: WorldTimezone? = nil
    @State private var renameText = ""
    @State private var showingSettings = false

    let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    var selectedDate: Date {
        now.addingTimeInterval(store.hourOffset * 3600)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(store.sortedTimezones(for: selectedDate)) { tz in
                            let isReference = tz.identifier == store.referenceTimezoneId
                            TimezoneRowView(
                                timezone: tz,
                                selectedDate: selectedDate,
                                localTimeZone: store.referenceTimeZone,
                                hourOffset: $store.hourOffset,
                                isHighlighted: isReference,
                                use24Hour: store.use24Hour,
                                onDateTap: {
                                    pickerTimeZone = tz.timeZone
                                    pickerDate = selectedDate
                                    showingDatePicker = true
                                }
                            )
                            .onTapGesture {
                                store.referenceTimezoneId = tz.identifier
                            }
                            .contextMenu {
                                Button {
                                    store.referenceTimezoneId = tz.identifier
                                } label: {
                                    Label(isReference ? "Reference timezone" : "Set as reference", systemImage: "pin")
                                }
                                Button {
                                    renameText = tz.label
                                    renamingTimezone = tz
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                if tz.timeZone.identifier != TimeZone.current.identifier {
                                    Button(role: .destructive) {
                                        store.remove(tz)
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                            }
                            .swipeActions(edge: .trailing) {
                                if tz.timeZone.identifier != TimeZone.current.identifier {
                                    Button(role: .destructive) {
                                        store.remove(tz)
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 0)
                }

                Divider()

                // Footer
                Button {
                    withAnimation(.easeOut(duration: 0.3)) {
                        store.hourOffset = 0
                    }
                } label: {
                    Text("Reset")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(store.hourOffset != 0 ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(store.hourOffset != 0 ? Color.primary.opacity(0.25) : Color.primary.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
                .disabled(store.hourOffset == 0)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .navigationTitle("Time Zones")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddTimezoneView(isShowing: $showingAdd)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    List {
                        Section {
                            Toggle("24-hour time", isOn: $store.use24Hour)
                        }
                        Section("Tips") {
                            Label("Drag the slider horizontally to change time", systemImage: "arrow.left.and.right")
                            Label("Long-press a time zone to rename or delete it", systemImage: "hand.tap")
                            Label("Double-tap the slider to reset to current time", systemImage: "arrow.uturn.backward")
                            Label("Tap the date to open a calendar picker", systemImage: "calendar")
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    }
                    .navigationTitle("Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingSettings = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showingDatePicker) {
                NavigationStack {
                    VStack {
                        DatePicker("", selection: $pickerDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .environment(\.timeZone, pickerTimeZone)
                            .padding(.horizontal, 16)
                            .onChange(of: pickerDate) { newDate in
                                let now = Date()
                                var refCal = Calendar.current
                                refCal.timeZone = pickerTimeZone
                                let pickedComps = refCal.dateComponents([.year, .month, .day], from: newDate)
                                let timeComps = refCal.dateComponents([.hour, .minute, .second], from: selectedDate)
                                var target = DateComponents()
                                target.year = pickedComps.year
                                target.month = pickedComps.month
                                target.day = pickedComps.day
                                target.hour = timeComps.hour
                                target.minute = timeComps.minute
                                target.second = timeComps.second
                                if let targetDate = refCal.date(from: target) {
                                    let diff = targetDate.timeIntervalSince(now) / 3600.0
                                    store.hourOffset = (diff * 60).rounded() / 60
                                }
                            }

                        Button("Today") {
                            store.hourOffset = 0
                            showingDatePicker = false
                        }
                        .padding(.bottom, 16)

                        Spacer()
                    }
                    .navigationTitle("Jump to Date")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingDatePicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .alert("Rename", isPresented: Binding(
                get: { renamingTimezone != nil },
                set: { if !$0 { renamingTimezone = nil } }
            )) {
                TextField("City name", text: $renameText)
                Button("Rename") {
                    if let tz = renamingTimezone, !renameText.isEmpty {
                        store.rename(tz, to: renameText)
                    }
                    renamingTimezone = nil
                }
                Button("Cancel", role: .cancel) {
                    renamingTimezone = nil
                }
            }
        }
        .onReceive(timer) { _ in
            now = Date()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                now = Date()
            }
        }
    }
}
