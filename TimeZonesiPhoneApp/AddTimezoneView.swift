import SwiftUI

struct AddTimezoneView: View {
    @EnvironmentObject var store: TimezoneStore
    @Binding var isShowing: Bool
    @State private var searchText = ""

    // (identifier, display label, search aliases)
    static let commonTimezones: [(String, String, [String])] = [
        // UTC
        ("UTC", "UTC", ["utc", "gmt", "coordinated universal time", "greenwich mean time"]),

        // Americas
        ("Pacific/Honolulu", "Honolulu, US", ["hawaii"]),
        ("America/Anchorage", "Anchorage, US", ["alaska"]),
        ("America/Los_Angeles", "Los Angeles, US", ["san francisco", "seattle", "portland", "vancouver", "pacific", "california", "la"]),
        ("America/Denver", "Denver, US", ["mountain", "salt lake city", "phoenix"]),
        ("America/Chicago", "Chicago, US", ["central", "houston", "dallas", "austin", "minneapolis"]),
        ("America/New_York", "New York, US", ["eastern", "boston", "philadelphia", "washington dc", "miami", "atlanta", "detroit"]),
        ("America/Toronto", "Toronto, Canada", ["montreal", "ottawa"]),
        ("America/Halifax", "Halifax, Canada", ["atlantic canada", "nova scotia"]),
        ("America/Mexico_City", "Mexico City, Mexico", ["guadalajara"]),
        ("America/Bogota", "Bogota, Colombia", []),
        ("America/Lima", "Lima, Peru", []),
        ("America/Santiago", "Santiago, Chile", []),
        ("America/Sao_Paulo", "São Paulo, Brazil", ["rio de janeiro", "rio"]),
        ("America/Argentina/Buenos_Aires", "Buenos Aires, Argentina", []),

        // Europe
        ("Atlantic/Reykjavik", "Reykjavik, Iceland", []),
        ("Europe/London", "London, UK", ["united kingdom", "britain", "edinburgh", "manchester"]),
        ("Europe/Dublin", "Dublin, Ireland", []),
        ("Europe/Lisbon", "Lisbon, Portugal", []),
        ("Europe/Paris", "Paris, France", ["brussels", "lyon"]),
        ("Europe/Berlin", "Berlin, Germany", ["munich", "frankfurt", "hamburg"]),
        ("Europe/Amsterdam", "Amsterdam, Netherlands", ["holland"]),
        ("Europe/Rome", "Rome, Italy", ["milan"]),
        ("Europe/Madrid", "Madrid, Spain", ["barcelona"]),
        ("Europe/Zurich", "Zurich, Switzerland", ["geneva", "bern"]),
        ("Europe/Vienna", "Vienna, Austria", []),
        ("Europe/Prague", "Prague, Czechia", ["czech"]),
        ("Europe/Warsaw", "Warsaw, Poland", ["krakow"]),
        ("Europe/Stockholm", "Stockholm, Sweden", []),
        ("Europe/Oslo", "Oslo, Norway", []),
        ("Europe/Copenhagen", "Copenhagen, Denmark", []),
        ("Europe/Helsinki", "Helsinki, Finland", []),
        ("Europe/Bucharest", "Bucharest, Romania", []),
        ("Europe/Sofia", "Sofia, Bulgaria", []),
        ("Europe/Athens", "Athens, Greece", []),
        ("Europe/Istanbul", "Istanbul, Turkey", ["ankara"]),
        ("Europe/Kiev", "Kyiv, Ukraine", []),
        ("Europe/Moscow", "Moscow, Russia", ["st petersburg", "saint petersburg"]),

        // Africa
        ("Africa/Casablanca", "Casablanca, Morocco", ["rabat"]),
        ("Africa/Lagos", "Lagos, Nigeria", ["west africa"]),
        ("Africa/Accra", "Accra, Ghana", []),
        ("Africa/Cairo", "Cairo, Egypt", []),
        ("Africa/Nairobi", "Nairobi, Kenya", ["east africa", "addis ababa", "ethiopia"]),
        ("Africa/Johannesburg", "Johannesburg, South Africa", ["cape town", "durban", "pretoria"]),

        // Middle East
        ("Asia/Dubai", "Dubai, UAE", ["abu dhabi", "united arab emirates"]),
        ("Asia/Riyadh", "Riyadh, Saudi Arabia", ["jeddah"]),
        ("Asia/Tehran", "Tehran, Iran", []),
        ("Asia/Jerusalem", "Jerusalem, Israel", ["tel aviv"]),

        // South & Southeast Asia
        ("Asia/Karachi", "Karachi, Pakistan", ["lahore", "islamabad"]),
        ("Asia/Kolkata", "Mumbai, India", ["delhi", "bangalore", "bengaluru", "chennai", "hyderabad", "kolkata", "new delhi"]),
        ("Asia/Colombo", "Colombo, Sri Lanka", []),
        ("Asia/Dhaka", "Dhaka, Bangladesh", []),
        ("Asia/Bangkok", "Bangkok, Thailand", []),
        ("Asia/Ho_Chi_Minh", "Ho Chi Minh City, Vietnam", ["saigon", "hanoi"]),
        ("Asia/Jakarta", "Jakarta, Indonesia", []),
        ("Asia/Singapore", "Singapore", ["sg"]),
        ("Asia/Kuala_Lumpur", "Kuala Lumpur, Malaysia", ["kl"]),
        ("Asia/Manila", "Manila, Philippines", []),

        // East Asia
        ("Asia/Hong_Kong", "Hong Kong", ["hk"]),
        ("Asia/Shanghai", "Shanghai, China", ["beijing", "shenzhen", "guangzhou", "chengdu"]),
        ("Asia/Taipei", "Taipei, Taiwan", []),
        ("Asia/Seoul", "Seoul, South Korea", ["korea"]),
        ("Asia/Tokyo", "Tokyo, Japan", ["osaka"]),

        // Oceania
        ("Australia/Perth", "Perth, Australia", ["western australia"]),
        ("Australia/Adelaide", "Adelaide, Australia", ["south australia"]),
        ("Australia/Sydney", "Sydney, Australia", ["new south wales"]),
        ("Australia/Melbourne", "Melbourne, Australia", ["victoria"]),
        ("Australia/Brisbane", "Brisbane, Australia", ["queensland"]),
        ("Pacific/Auckland", "Auckland, New Zealand", ["wellington"]),
        ("Pacific/Fiji", "Fiji", ["suva"]),
    ]

    var displayedTimezones: [(String, String)] {
        if searchText.isEmpty {
            return Self.commonTimezones.map { ($0.0, $0.1) }
        }
        let query = searchText.lowercased()

        let commonMatches = Self.commonTimezones.filter { (id, label, aliases) in
            id.lowercased().contains(query) ||
            label.lowercased().contains(query) ||
            aliases.contains(where: { $0.contains(query) })
        }.map { ($0.0, $0.1) }

        let matchedIds = Set(commonMatches.map { $0.0 })
        let allMatches = TimeZone.knownTimeZoneIdentifiers
            .filter { id in
                !matchedIds.contains(id) &&
                (id.lowercased().contains(query) ||
                 (id.components(separatedBy: "/").last?.replacingOccurrences(of: "_", with: " ").lowercased().contains(query) ?? false))
            }
            .map { id in
                let label = id.components(separatedBy: "/").last?.replacingOccurrences(of: "_", with: " ") ?? id
                return (id, label)
            }

        return commonMatches + allMatches
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(displayedTimezones, id: \.0) { (id, label) in
                    let alreadyAdded = store.timezones.contains { $0.identifier == id }
                    Button {
                        if !alreadyAdded {
                            store.add(WorldTimezone(identifier: id, label: label))
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(label)
                                    .foregroundColor(.primary)
                                if let tz = TimeZone(identifier: id) {
                                    let now = Date()
                                    let offset = tz.secondsFromGMT(for: now)
                                    let h = offset / 3600
                                    let m = abs(offset % 3600) / 60
                                    let utcLabel = m == 0
                                        ? String(format: "UTC%+d", h)
                                        : String(format: "UTC%+d:%02d", h, m)
                                    Text("\(tz.abbreviation(for: now) ?? "") · \(utcLabel)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if alreadyAdded {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search cities or timezones...")
            .navigationTitle("Add Timezone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        isShowing = false
                    }
                }
            }
        }
    }
}
