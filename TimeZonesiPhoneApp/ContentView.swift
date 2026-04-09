import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: TimezoneStore
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
                            let isReference = tz.timeZone.identifier == store.referenceTimezoneId
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
                                store.referenceTimezoneId = tz.timeZone.identifier
                            }
                            .contextMenu {
                                Button {
                                    store.referenceTimezoneId = tz.timeZone.identifier
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
                HStack {
                    Spacer()
                    Button("Reset") {
                        withAnimation(.easeOut(duration: 0.3)) {
                            store.hourOffset = 0
                        }
                    }
                    .font(.system(size: 14))
                    .disabled(store.hourOffset == 0)
                    .opacity(store.hourOffset != 0 ? 1 : 0.4)
                    Spacer()
                }
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
    }
}
