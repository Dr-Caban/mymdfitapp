import SwiftUI

struct ProgressView: View {
    @State private var entries: [ProgressEntry] = ProgressEntry.samples
    @State private var showLogSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Summary cards
                    summaryCards

                    // Pain trend chart
                    painTrendSection

                    // Recent entries
                    recentEntriesSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showLogSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.mdOrange)
                    }
                }
            }
            .sheet(isPresented: $showLogSheet) {
                LogProgressView()
            }
        }
    }

    private var summaryCards: some View {
        HStack(spacing: 12) {
            SummaryCard(
                title: "Current Pain",
                value: "\(entries.first?.painLevel ?? 0)",
                subtitle: entries.first?.painLevelDescription ?? "",
                icon: "waveform.path.ecg",
                color: painColor(for: entries.first?.painLevel ?? 0)
            )

            SummaryCard(
                title: "Mobility",
                value: "\(entries.first?.mobilityScore ?? 0)%",
                subtitle: "Assessment",
                icon: "figure.walk",
                color: .mdOrange
            )

            SummaryCard(
                title: "Streak",
                value: "5",
                subtitle: "Days active",
                icon: "flame.fill",
                color: .mdOrange
            )
        }
    }

    private var painTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pain Level Trend")
                .font(.mdHeadline)

            // Chart placeholder
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(Array(entries.reversed().enumerated()), id: \.offset) { index, entry in
                    VStack {
                        Spacer()
                        RoundedRectangle(cornerRadius: 4)
                            .fill(painColor(for: entry.painLevel))
                            .frame(width: 40, height: CGFloat(entry.painLevel * 15 + 20))

                        Text(entry.date, format: .dateTime.weekday(.abbreviated))
                            .font(.system(size: 10))
                            .foregroundColor(.mdGray)
                    }
                }
            }
            .frame(height: 180)
            .frame(maxWidth: .infinity)
        }
        .mdCard()
    }

    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Logs")
                .font(.mdHeadline)

            ForEach(entries) { entry in
                ProgressEntryRow(entry: entry)
            }
        }
        .mdCard()
    }

    private func painColor(for level: Int) -> Color {
        switch level {
        case 0...3: return .mdSuccess
        case 4...6: return .mdWarning
        default: return .mdError
        }
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 24, weight: .bold))

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.mdGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

struct ProgressEntryRow: View {
    let entry: ProgressEntry

    var body: some View {
        HStack(spacing: 12) {
            // Pain indicator
            Circle()
                .fill(painColor(for: entry.painLevel))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Pain: \(entry.painLevel)/10")
                        .font(.mdBody)
                    if let location = entry.painLocation {
                        Text("• \(location.displayName)")
                            .font(.mdCaption)
                            .foregroundColor(.mdGray)
                    }
                }
                Text(entry.formattedDate)
                    .font(.mdCaption)
                    .foregroundColor(.mdGray)
            }

            Spacer()

            if let mood = entry.mood {
                Text(mood.emoji)
                    .font(.system(size: 24))
            }
        }
        .padding(.vertical, 4)
    }

    private func painColor(for level: Int) -> Color {
        switch level {
        case 0...3: return .mdSuccess
        case 4...6: return .mdWarning
        default: return .mdError
        }
    }
}

struct LogProgressView: View {
    @Environment(\.dismiss) var dismiss
    @State private var painLevel: Double = 5
    @State private var painLocation: TargetArea = .lowerBack
    @State private var mood: Mood = .okay
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Pain Level") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Current pain")
                            Spacer()
                            Text("\(Int(painLevel))/10")
                                .font(.mdHeadline)
                                .foregroundColor(painColor)
                        }
                        Slider(value: $painLevel, in: 0...10, step: 1)
                            .tint(painColor)
                    }

                    Picker("Location", selection: $painLocation) {
                        ForEach(TargetArea.allCases, id: \.self) { area in
                            Text(area.displayName).tag(area)
                        }
                    }
                }

                Section("How are you feeling?") {
                    Picker("Mood", selection: $mood) {
                        ForEach(Mood.allCases, id: \.self) { m in
                            Text("\(m.emoji) \(m.displayName)").tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }

                Section {
                    Button("Save Entry") {
                        // TODO: Save entry
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.mdOrange)
                }
            }
            .navigationTitle("Log Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var painColor: Color {
        switch Int(painLevel) {
        case 0...3: return .mdSuccess
        case 4...6: return .mdWarning
        default: return .mdError
        }
    }
}

#Preview {
    ProgressView()
}
