import SwiftUI

struct ExercisesView: View {
    @State private var selectedCategory: ExerciseCategory?
    @State private var searchText = ""

    var filteredExercises: [Exercise] {
        var exercises = Exercise.samples
        if let category = selectedCategory {
            exercises = exercises.filter { $0.category == category }
        }
        if !searchText.isEmpty {
            exercises = exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        return exercises
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Category filter
                    categoryFilter

                    // Prescribed exercises
                    if selectedCategory == nil {
                        prescribedSection
                    }

                    // All exercises
                    allExercisesSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Exercises")
            .searchable(text: $searchText, prompt: "Search exercises")
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryPill(
                    title: "All",
                    isSelected: selectedCategory == nil
                ) {
                    withAnimation { selectedCategory = nil }
                }

                ForEach(ExerciseCategory.allCases, id: \.self) { category in
                    CategoryPill(
                        title: category.displayName,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation { selectedCategory = category }
                    }
                }
            }
        }
    }

    private var prescribedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.mdOrange)
                Text("Prescribed for You")
                    .font(.mdHeadline)
            }

            ForEach(Exercise.samples.filter { $0.isPrescribed }) { exercise in
                ExerciseCard(exercise: exercise)
            }
        }
    }

    private var allExercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercise Library")
                .font(.mdHeadline)

            if filteredExercises.isEmpty {
                Text("No exercises found")
                    .font(.mdSubheadline)
                    .foregroundColor(.mdGray)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
            } else {
                ForEach(filteredExercises) { exercise in
                    ExerciseCard(exercise: exercise)
                }
            }
        }
    }
}

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.mdOrange : Color(.systemBackground))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.mdOrange.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                )
        }
    }
}

struct ExerciseCard: View {
    let exercise: Exercise
    @State private var showDetail = false

    var body: some View {
        Button {
            showDetail = true
        } label: {
            HStack(spacing: 16) {
                // Thumbnail
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.mdOrange.opacity(0.1))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: exercise.category.icon)
                            .font(.system(size: 28))
                            .foregroundColor(.mdOrange)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(exercise.name)
                            .font(.mdHeadline)
                            .foregroundColor(.primary)

                        if exercise.isPrescribed {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.mdOrange)
                        }
                    }

                    Text(exercise.category.displayName)
                        .font(.mdCaption)
                        .foregroundColor(.mdGray)

                    HStack(spacing: 12) {
                        if let duration = exercise.formattedDuration {
                            Label(duration, systemImage: "clock")
                        }
                        Label(exercise.difficulty.displayName, systemImage: "chart.bar")
                    }
                    .font(.system(size: 11))
                    .foregroundColor(.mdGray)
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.mdOrange)
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
        .sheet(isPresented: $showDetail) {
            ExerciseDetailView(exercise: exercise)
        }
    }
}

struct ExerciseDetailView: View {
    let exercise: Exercise
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Video placeholder
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.mdDark)
                        .frame(height: 220)
                        .overlay(
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.white)
                        )

                    VStack(alignment: .leading, spacing: 16) {
                        // Title and meta
                        VStack(alignment: .leading, spacing: 8) {
                            Text(exercise.name)
                                .font(.mdTitle)

                            HStack(spacing: 16) {
                                Label(exercise.category.displayName, systemImage: exercise.category.icon)
                                Label(exercise.difficulty.displayName, systemImage: "chart.bar")
                                if let duration = exercise.formattedDuration {
                                    Label(duration, systemImage: "clock")
                                }
                            }
                            .font(.mdCaption)
                            .foregroundColor(.mdGray)
                        }

                        // Description
                        Text(exercise.description)
                            .font(.mdBody)
                            .foregroundColor(.mdGray)

                        // Target areas
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target Areas")
                                .font(.mdHeadline)

                            HStack {
                                ForEach(exercise.targetAreas, id: \.self) { area in
                                    Text(area.displayName)
                                        .font(.system(size: 12, weight: .medium))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.mdOrange.opacity(0.1))
                                        .foregroundColor(.mdOrange)
                                        .cornerRadius(16)
                                }
                            }
                        }

                        // Instructions
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Instructions")
                                .font(.mdHeadline)

                            ForEach(Array(exercise.instructions.enumerated()), id: \.offset) { index, instruction in
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.mdOrange)
                                        .clipShape(Circle())

                                    Text(instruction)
                                        .font(.mdBody)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ExercisesView()
}
