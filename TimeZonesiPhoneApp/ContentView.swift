import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: TimezoneStore
    @State private var now = Date()
    @State private var showingAdd = false
    @State private var showingDatePicker = false
    @State private var pickerDate = Date()
    @State private var renamingTimezone: WorldTimezone? = nil
    @State private var renameText = ""

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
                                onDateTap: {
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
                    .padding(.vertical, 4)
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
            .sheet(isPresented: $showingDatePicker) {
                NavigationStack {
                    VStack {
                        DatePicker("", selection: $pickerDate, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .padding(.horizontal, 16)
                            .onChange(of: pickerDate) { newDate in
                                let now = Date()
                                let diff = newDate.timeIntervalSince(now) / 3600.0
                                store.hourOffset = (diff * 60).rounded() / 60
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
