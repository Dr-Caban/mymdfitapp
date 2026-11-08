import SwiftUI

// MARK: - Video Library Main View

struct VideoLibraryView: View {
    @State private var searchText = ""
    @State private var selectedKind: VideoKind = .exercise
    @State private var selectedCategory: String? = nil
    @State private var selectedLocation: String = "All"
    @State private var organizeBy: OrganizeBy = .joint
    @State private var selectedExercise: Exercise?

    enum VideoKind: String, CaseIterable {
        case exercise = "Exercise"
        case rehab = "Rehab"
        case all = "All"

        var description: String {
            switch self {
            case .exercise:
                return "Strength training and specialty movements for building fitness."
            case .rehab:
                return "Dr. Jared's corrective movements, kept gentle for rehabilitation."
            case .all:
                return "Browse all exercises in the library."
            }
        }
    }

    enum OrganizeBy: String, CaseIterable {
        case joint = "By joint"
        case muscle = "By muscle"
    }

    private let locations = ["All", "Home", "Gym", "Outdoor", "Minimal", "Hotel", "Office"]
    private let categories = ["Upper Body", "Lower Body", "Core", "Cardio", "Mobility", "Rehab"]

    private var filteredExercises: [Exercise] {
        Exercise.samples.filter { exercise in
            let matchesSearch = searchText.isEmpty ||
                exercise.name.localizedCaseInsensitiveContains(searchText) ||
                exercise.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }

            let matchesCategory = selectedCategory == nil ||
                exercise.category.displayName == selectedCategory

            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Background
                Color.mdCream
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Hero header
                        heroSection

                        // Filters and content
                        VStack(spacing: 14) {
                            // Intro button
                            introButton

                            // Kind filter (Exercise/Rehab/All)
                            kindSegment

                            // Kind description
                            Text(selectedKind.description)
                                .font(.system(size: 13))
                                .foregroundColor(.mdMuted)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)

                            // Location chips
                            locationChips

                            // Search bar
                            searchBar

                            // Category chips
                            categoryChips

                            // Organize by
                            organizeBySection

                            // Video grid
                            videoGrid

                            // Empty state
                            if filteredExercises.isEmpty {
                                emptyState
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedExercise) { exercise in
                ExerciseDetailView(exercise: exercise)
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        ZStack {
            // Navy background with radial gradient
            Color.mdInk
            RadialGradient(
                colors: [Color.mdInk3.opacity(0.5), .clear],
                center: .topTrailing,
                startRadius: 0,
                endRadius: 300
            )
        }
        .frame(height: 120)
        .overlay(
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Video ")
                        .font(.mdDisplay(30, weight: .bold))
                        .foregroundColor(.white)
                    +
                    Text("Library")
                        .font(.mdDisplay(30, weight: .bold))
                        .italic()
                        .foregroundColor(.mdGold)
                }

                Text("BROWSE. LEARN. MOVE BETTER.")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.mdOnNavy)
                    .tracking(1.2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            ,
            alignment: .bottomLeading
        )
    }

    // MARK: - Intro Button

    private var introButton: some View {
        Button {
            // Show intro video
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.mdAccent)

                Text("Start here: how to use the library")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.mdInk)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.mdPaper)
            .cornerRadius(999)
            .overlay(
                RoundedRectangle(cornerRadius: 999)
                    .stroke(Color.mdLine, lineWidth: 1.5)
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Kind Segment

    private var kindSegment: some View {
        HStack(spacing: 0) {
            ForEach(VideoKind.allCases, id: \.self) { kind in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedKind = kind
                    }
                } label: {
                    Text(kind.rawValue)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(selectedKind == kind ? .white : .mdInk)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedKind == kind ? Color.mdInk : Color.clear)
                }
            }
        }
        .background(Color.mdPaper)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.mdLine, lineWidth: 1.5)
        )
    }

    // MARK: - Location Chips

    private var locationChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(locations, id: \.self) { location in
                    MDChip(
                        title: location,
                        isSelected: selectedLocation == location
                    ) {
                        selectedLocation = location
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.mdMuted)

            TextField("Search exercises", text: $searchText)
                .font(.system(size: 15))
                .foregroundColor(.mdText)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.mdMuted)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.mdPaper)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.mdLine, lineWidth: 1.5)
        )
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                MDChip(
                    title: "All",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }

                ForEach(categories, id: \.self) { category in
                    MDChip(
                        title: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Organize By Section

    private var organizeBySection: some View {
        HStack {
            // Segment
            HStack(spacing: 0) {
                ForEach(OrganizeBy.allCases, id: \.self) { by in
                    Button {
                        organizeBy = by
                    } label: {
                        Text(by.rawValue)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(organizeBy == by ? .white : .mdInk)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(organizeBy == by ? Color.mdInk : Color.clear)
                    }
                }
            }
            .background(Color.mdPaper)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.mdLine, lineWidth: 1.5)
            )

            Spacer()

            // Jump to dropdown (simplified)
            Menu {
                Button("Head & Neck") {}
                Button("Shoulders") {}
                Button("Upper Back") {}
                Button("Lower Back") {}
                Button("Core") {}
                Button("Hips") {}
                Button("Legs") {}
                Button("Feet & Ankles") {}
            } label: {
                HStack(spacing: 6) {
                    Text("Jump to")
                        .font(.system(size: 14, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.mdInk)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.mdPaper)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.mdLine, lineWidth: 1.5)
                )
            }
        }
    }

    // MARK: - Video Grid

    private var videoGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(filteredExercises) { exercise in
                VideoCard(exercise: exercise) {
                    selectedExercise = exercise
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        Text("No exercises match. Try another filter.")
            .font(.system(size: 14))
            .foregroundColor(.mdMuted)
            .padding(.vertical, 40)
    }
}

// MARK: - MD Chip

struct MDChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(isSelected ? .white : .mdInk)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.mdInk : Color.mdPaper)
                .cornerRadius(999)
                .overlay(
                    RoundedRectangle(cornerRadius: 999)
                        .stroke(isSelected ? Color.mdInk : Color.mdLine, lineWidth: 1.5)
                )
        }
    }
}

// MARK: - Video Card

struct VideoCard: View {
    let exercise: Exercise
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.mdInk3)
                        .aspectRatio(16/10, contentMode: .fit)

                    // Play button overlay
                    Circle()
                        .fill(Color.mdAccent.opacity(0.95))
                        .frame(width: 26, height: 26)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.mdInk)
                                .offset(x: 1)
                        )
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.mdInk)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(exercise.bodyRegion.displayName)
                        .font(.system(size: 12.5))
                        .foregroundColor(.mdMuted)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .background(Color.mdPaper)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.mdLine, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Exercise Detail View

struct ExerciseDetailView: View {
    @Environment(\.dismiss) var dismiss
    let exercise: Exercise
    @State private var isPlaying = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Video Player
                    videoPlayer

                    // Exercise Info
                    exerciseInfo

                    // Prescription
                    prescriptionSection

                    // Cues
                    if !exercise.cues.isEmpty {
                        cuesSection
                    }

                    // Modifications
                    if !exercise.modifications.isEmpty {
                        modificationsSection
                    }

                    // Safety Notes
                    if let safetyNotes = exercise.safetyNotes {
                        safetySection(safetyNotes)
                    }

                    // Related Exercises
                    relatedExercisesSection
                }
                .padding()
            }
            .background(Color.mdCream)
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.mdMuted)
                    }
                }
            }
        }
    }

    // MARK: - Video Player

    private var videoPlayer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.mdInk)
                .aspectRatio(16/9, contentMode: .fit)

            if isPlaying {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white)
            } else {
                Button {
                    isPlaying = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.mdAccent)
                            .frame(width: 72, height: 72)

                        Image(systemName: "play.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.mdInk)
                            .offset(x: 2)
                    }
                }
            }
        }
    }

    // MARK: - Exercise Info

    private var exerciseInfo: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tags row
            HStack(spacing: 8) {
                MDTagBadge(text: exercise.category.displayName, color: .mdAccentText)
                MDTagBadge(text: exercise.bodyRegion.displayName, color: .mdGold)
                MDTagBadge(text: exercise.level.displayName, color: .mdAccentText)
            }

            // Equipment
            if !exercise.equipment.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "dumbbell.fill")
                        .foregroundColor(.mdMuted)
                    Text(exercise.equipment.map(\.displayName).joined(separator: ", "))
                        .font(.system(size: 14))
                        .foregroundColor(.mdText)
                }
            }

            // Muscle emphasis
            if !exercise.muscleEmphasis.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .foregroundColor(.mdMuted)
                    Text(exercise.muscleEmphasis.joined(separator: ", "))
                        .font(.system(size: 14))
                        .foregroundColor(.mdText)
                }
            }
        }
        .mdCardStyle()
    }

    // MARK: - Prescription Section

    private var prescriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Default Prescription")
                .font(.mdDisplay(16, weight: .bold))
                .foregroundColor(.mdHeading)

            HStack(spacing: 24) {
                if let sets = exercise.defaultPrescription.sets {
                    MDPrescriptionItem(label: "Sets", value: "\(sets)")
                }
                if let reps = exercise.defaultPrescription.reps {
                    MDPrescriptionItem(label: "Reps", value: "\(reps)")
                }
                if let tempo = exercise.defaultPrescription.tempo {
                    MDPrescriptionItem(label: "Tempo", value: tempo)
                }
                if let duration = exercise.defaultPrescription.duration {
                    MDPrescriptionItem(label: "Duration", value: "\(duration)")
                }
            }
        }
        .mdCardStyle()
    }

    // MARK: - Cues Section

    private var cuesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coaching Cues")
                .font(.mdDisplay(16, weight: .bold))
                .foregroundColor(.mdHeading)

            ForEach(Array(exercise.cues.enumerated()), id: \.offset) { index, cue in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(index + 1)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.mdInk)
                        .clipShape(Circle())

                    Text(cue)
                        .font(.system(size: 14))
                        .foregroundColor(.mdText)
                }
            }
        }
        .mdCardStyle()
    }

    // MARK: - Modifications Section

    private var modificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Modifications")
                .font(.mdDisplay(16, weight: .bold))
                .foregroundColor(.mdHeading)

            ForEach(exercise.modifications, id: \.self) { mod in
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.branch")
                        .foregroundColor(.mdGold)
                    Text(mod)
                        .font(.system(size: 14))
                        .foregroundColor(.mdText)
                }
            }
        }
        .mdCardStyle()
    }

    // MARK: - Safety Section

    private func safetySection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Safety Notes", systemImage: "exclamationmark.triangle.fill")
                .font(.mdDisplay(16, weight: .bold))
                .foregroundColor(.mdErr)

            Text(notes)
                .font(.system(size: 14))
                .foregroundColor(.mdText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.mdErr.opacity(0.1))
        .cornerRadius(MDTheme.radius)
    }

    // MARK: - Related Exercises

    private var relatedExercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Exercises")
                .font(.mdDisplay(16, weight: .bold))
                .foregroundColor(.mdHeading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Exercise.samples.filter { $0.id != exercise.id }.prefix(4)) { related in
                        MDRelatedExerciseCard(exercise: related)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct MDTagBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(6)
    }
}

struct MDPrescriptionItem: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.mdAccentText)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.mdMuted)
        }
    }
}

struct MDRelatedExerciseCard: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 9)
                .fill(Color.mdInk3)
                .frame(width: 120, height: 80)
                .overlay(
                    Circle()
                        .fill(Color.mdAccent.opacity(0.95))
                        .frame(width: 26, height: 26)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.mdInk)
                                .offset(x: 1)
                        )
                )

            Text(exercise.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.mdInk)
                .lineLimit(2)
                .frame(width: 120, alignment: .leading)
        }
    }
}

// MARK: - Legacy Support Views (for backwards compatibility)

struct FilterChip: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    init(title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        MDChip(title: title, isSelected: isSelected, action: action)
    }
}

struct DarkFilterChip: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    init(title: String, icon: String? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        MDChip(title: title, isSelected: isSelected, action: action)
    }
}

struct TagBadge: View {
    let text: String
    let color: Color

    var body: some View {
        MDTagBadge(text: text, color: color)
    }
}

struct PrescriptionItem: View {
    let label: String
    let value: String

    init(label: String, value: String) {
        self.label = label
        self.value = value
    }

    init(label: String, value: Int) {
        self.label = label
        self.value = "\(value)"
    }

    var body: some View {
        MDPrescriptionItem(label: label, value: value)
    }
}

struct RelatedExerciseCard: View {
    let exercise: Exercise

    var body: some View {
        MDRelatedExerciseCard(exercise: exercise)
    }
}

// MARK: - Preview

struct VideoLibraryView_Previews: PreviewProvider {
    static var previews: some View {
        VideoLibraryView()
    }
}
