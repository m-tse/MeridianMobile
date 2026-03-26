import SwiftUI

@main
struct TimeZonesiPhoneAppApp: App {
    @StateObject private var store = TimezoneStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
