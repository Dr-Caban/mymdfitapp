import Foundation
import SwiftUI

// MARK: - WorkoutService

/// Service responsible for generating, managing, and persisting workouts.
/// Uses intelligent exercise selection based on goal type, equipment, difficulty, and location.
@MainActor
class WorkoutService: ObservableObject {

    // MARK: - Published Properties

    @Published var generatedWorkout: Workout?
    @Published var workoutHistory: [Workout] = []
    @Published var isGenerating = false
    @Published var isLoading = false
    @Published var error: WorkoutServiceError?

    // MARK: - Private Properties

    private let historyKey = "mdfit_workout_history"
    private let maxHistoryCount = 100

    /// Exercise database - in production, this would come from an API/database
    private var exerciseDatabase: [Exercise] = []

    // MARK: - Initialization

    init() {
        loadWorkoutHistory()
        loadExerciseDatabase()
    }

    // MARK: - Workout Generation

    /// Generates a workout based on the provided settings using intelligent exercise selection.
    /// - Parameter settings: The workout generator settings from the UI
    /// - Returns: A fully populated Workout ready for execution
    func generateWorkout(from settings: WorkoutGeneratorSettings) async throws -> Workout {
        isGenerating = true
        error = nil

        defer { isGenerating = false }

        // Simulate network/processing delay for realistic UX
        try await Task.sleep(nanoseconds: 500_000_000)

        // Get available equipment for the location
        let availableEquipment = equipmentForLocation(settings.location, restrictions: settings.addOns)

        // Get body regions for the goal type
        let targetRegions = bodyRegionsForGoal(settings.goalType)

        // Filter exercises based on all criteria
        let eligibleExercises = filterExercises(
            goalType: settings.goalType,
            targetRegions: targetRegions,
            availableEquipment: availableEquipment,
            difficulty: settings.difficulty,
            restrictedEquipment: settings.addOns.restrictedEquipment
        )

        guard eligibleExercises.count >= settings.exercisesPerRound else {
            throw WorkoutServiceError.insufficientExercises(
                required: settings.exercisesPerRound,
                available: eligibleExercises.count
            )
        }

        // Calculate workout structure
        let workoutStructure = calculateWorkoutStructure(settings: settings)

        // Select exercises with intelligent randomization
        let selectedExercises = selectExercises(
            from: eligibleExercises,
            count: settings.exercisesPerRound,
            rounds: settings.totalRounds,
            goalType: settings.goalType,
            structure: workoutStructure
        )

        // Build workout exercises with prescriptions
        var workoutExercises: [WorkoutExercise] = []

        for round in 1...settings.totalRounds {
            for (index, exercise) in selectedExercises.enumerated() {
                let prescription = generatePrescription(
                    for: exercise,
                    difficulty: settings.difficulty,
                    structure: workoutStructure
                )

                let workoutExercise = WorkoutExercise(
                    id: UUID().uuidString,
                    exerciseId: exercise.id,
                    exercise: exercise,
                    roundNumber: round,
                    orderInRound: index + 1,
                    prescription: prescription,
                    isCompleted: false,
                    completedAt: nil
                )
                workoutExercises.append(workoutExercise)
            }
        }

        // Generate workout name
        let workoutName = generateWorkoutName(goalType: settings.goalType, difficulty: settings.difficulty)

        let workout = Workout(
            id: "wkt_\(UUID().uuidString.prefix(8))",
            userId: nil, // Set by caller if authenticated
            name: workoutName,
            goalType: settings.goalType,
            location: settings.location,
            difficulty: settings.difficulty,
            lengthMinutes: workoutStructure.totalDuration,
            exercisesPerRound: settings.exercisesPerRound,
            totalRounds: settings.totalRounds,
            restBetweenExercises: settings.restBetweenExercises,
            restBetweenRounds: settings.restBetweenRounds,
            addOns: settings.addOns,
            exercises: workoutExercises,
            scheduledDate: nil,
            completedAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        self.generatedWorkout = workout
        return workout
    }

    /// Generates a randomized workout with constrained randomization.
    /// Ensures variety while maintaining workout coherence.
    func generateRandomWorkout() async throws -> Workout {
        var settings = WorkoutGeneratorSettings()
        settings.randomize()

        // Apply constraints to randomization
        settings = applyRandomizationConstraints(to: settings)

        return try await generateWorkout(from: settings)
    }

    // MARK: - Exercise Selection Algorithm

    /// Filters exercises based on goal type, equipment, and difficulty criteria.
    private func filterExercises(
        goalType: WorkoutGoalType,
        targetRegions: Set<BodyRegion>,
        availableEquipment: Set<Equipment>,
        difficulty: DifficultyLevel,
        restrictedEquipment: [Equipment]?
    ) -> [Exercise] {

        let restrictedSet = Set(restrictedEquipment ?? [])

        return exerciseDatabase.filter { exercise in
            // Must be approved
            guard exercise.approvalStatus == .approved else { return false }

            // Match body region (or full body exercises apply to all)
            let regionMatch = targetRegions.contains(exercise.bodyRegion) ||
                              exercise.bodyRegion == .fullBody ||
                              targetRegions.contains(.fullBody)
            guard regionMatch else { return false }

            // Equipment must be available and not restricted
            let exerciseEquipmentSet = Set(exercise.equipment)
            let hasRequiredEquipment = exerciseEquipmentSet.isEmpty ||
                                       exerciseEquipmentSet.contains(.none) ||
                                       !exerciseEquipmentSet.isDisjoint(with: availableEquipment)
            guard hasRequiredEquipment else { return false }

            // Check equipment restrictions
            if !restrictedSet.isEmpty {
                let usesRestrictedEquipment = !exerciseEquipmentSet.isDisjoint(with: restrictedSet)
                if usesRestrictedEquipment { return false }
            }

            // Match difficulty (allow same or lower difficulty)
            guard isDifficultyAppropriate(exercise.level, for: difficulty) else { return false }

            // Category filtering for cardio goals
            if goalType == .cardio {
                let cardioCategories: Set<ExerciseCategory> = [.cardio, .power]
                guard cardioCategories.contains(exercise.category) else { return false }
            }

            return true
        }
    }

    /// Returns body regions relevant to the workout goal type.
    private func bodyRegionsForGoal(_ goalType: WorkoutGoalType) -> Set<BodyRegion> {
        switch goalType {
        case .upperBody:
            return [.neck, .shoulders, .upperBack, .chest, .arms, .core]
        case .lowerBody:
            return [.hips, .glutes, .quadriceps, .hamstrings, .knees, .calves, .ankles, .feet]
        case .fullBody:
            return Set(BodyRegion.allCases)
        case .core:
            return [.core, .lowerBack, .hips]
        case .mobility:
            return Set(BodyRegion.allCases)
        case .cardio:
            return [.fullBody, .core, .glutes, .quadriceps, .calves]
        case .environmental:
            return Set(BodyRegion.allCases)
        }
    }

    /// Returns available equipment based on workout location.
    private func equipmentForLocation(_ location: WorkoutLocation, restrictions: WorkoutAddOns) -> Set<Equipment> {
        var equipment: Set<Equipment>

        switch location {
        case .home:
            equipment = [.none, .yogaMat, .resistanceBand, .dumbbells, .foamRoller]
        case .gym:
            equipment = Set(Equipment.allCases)
        case .outdoor:
            equipment = [.none, .resistanceBand]
        case .office:
            equipment = [.none, .resistanceBand]
        case .pool:
            equipment = [.none]
        case .custom:
            // For custom, assume all equipment available unless restricted
            equipment = Set(Equipment.allCases)
        }

        // Remove restricted equipment
        if let restricted = restrictions.restrictedEquipment {
            equipment.subtract(restricted)
        }

        return equipment
    }

    /// Checks if an exercise difficulty is appropriate for the target difficulty.
    private func isDifficultyAppropriate(_ exerciseLevel: DifficultyLevel, for targetLevel: DifficultyLevel) -> Bool {
        let levels: [DifficultyLevel] = [.beginner, .intermediate, .advanced, .elite]
        guard let exerciseIndex = levels.firstIndex(of: exerciseLevel),
              let targetIndex = levels.firstIndex(of: targetLevel) else {
            return false
        }
        // Allow same level or one level below
        return exerciseIndex <= targetIndex && exerciseIndex >= targetIndex - 1
    }

    /// Selects exercises with intelligent distribution and randomization.
    private func selectExercises(
        from eligibleExercises: [Exercise],
        count: Int,
        rounds: Int,
        goalType: WorkoutGoalType,
        structure: WorkoutStructure
    ) -> [Exercise] {

        var selected: [Exercise] = []
        var remaining = eligibleExercises.shuffled()

        // Group exercises by body region for balanced selection
        var exercisesByRegion: [BodyRegion: [Exercise]] = [:]
        for exercise in remaining {
            exercisesByRegion[exercise.bodyRegion, default: []].append(exercise)
        }

        // Group exercises by category for variety
        var exercisesByCategory: [ExerciseCategory: [Exercise]] = [:]
        for exercise in remaining {
            exercisesByCategory[exercise.category, default: []].append(exercise)
        }

        // Select exercises with balanced distribution
        let regionsToTarget = Array(exercisesByRegion.keys).shuffled()
        var regionIndex = 0

        while selected.count < count && !remaining.isEmpty {
            let targetRegion = regionsToTarget[regionIndex % regionsToTarget.count]

            if var regionExercises = exercisesByRegion[targetRegion], !regionExercises.isEmpty {
                // Pick exercise not already selected
                if let exercise = regionExercises.first(where: { !selected.contains($0) }) {
                    selected.append(exercise)
                    regionExercises.removeAll { $0.id == exercise.id }
                    exercisesByRegion[targetRegion] = regionExercises
                    remaining.removeAll { $0.id == exercise.id }
                }
            }

            regionIndex += 1

            // Prevent infinite loop
            if regionIndex > count * 2 {
                // Fall back to random selection
                if let exercise = remaining.first(where: { !selected.contains($0) }) {
                    selected.append(exercise)
                    remaining.removeAll { $0.id == exercise.id }
                }
            }
        }

        // Ensure category variety - check for warm-up/cool-down add-ons
        if structure.includesWarmUp {
            // Move mobility/warm-up exercise to front if available
            if let warmUpIndex = selected.firstIndex(where: { $0.category == .warmUp || $0.category == .mobility }) {
                let warmUp = selected.remove(at: warmUpIndex)
                selected.insert(warmUp, at: 0)
            }
        }

        if structure.includesCoolDown {
            // Move stretching/cool-down exercise to end if available
            if let coolDownIndex = selected.firstIndex(where: { $0.category == .coolDown || $0.category == .stretching }) {
                let coolDown = selected.remove(at: coolDownIndex)
                selected.append(coolDown)
            }
        }

        return selected
    }

    // MARK: - Workout Structure Calculation

    /// Calculates the workout structure including timing and phases.
    private func calculateWorkoutStructure(settings: WorkoutGeneratorSettings) -> WorkoutStructure {
        // Base exercise time (average)
        let avgExerciseTime: Int
        switch settings.difficulty {
        case .beginner: avgExerciseTime = 45
        case .intermediate: avgExerciseTime = 60
        case .advanced: avgExerciseTime = 75
        case .elite: avgExerciseTime = 90
        }

        // Calculate core workout time
        let exerciseCount = settings.exercisesPerRound * settings.totalRounds
        let totalExerciseTime = exerciseCount * avgExerciseTime

        // Rest time
        let totalExerciseRest = (settings.exercisesPerRound - 1) * settings.totalRounds * settings.restBetweenExercises
        let totalRoundRest = (settings.totalRounds - 1) * settings.restBetweenRounds
        let totalRestTime = totalExerciseRest + totalRoundRest

        // Add-on times
        let warmUpTime = settings.addOns.warmUp ? 5 * 60 : 0
        let coolDownTime = settings.addOns.coolDown ? 5 * 60 : 0
        let coreTime = settings.addOns.coreWork ? 5 * 60 : 0
        let mobilityTime = settings.addOns.mobilityFlexibility ? 5 * 60 : 0

        let totalSeconds = totalExerciseTime + totalRestTime + warmUpTime + coolDownTime + coreTime + mobilityTime
        let totalMinutes = max(settings.lengthMinutes, Int(ceil(Double(totalSeconds) / 60.0)))

        return WorkoutStructure(
            totalDuration: totalMinutes,
            exerciseTime: avgExerciseTime,
            includesWarmUp: settings.addOns.warmUp,
            includesCoolDown: settings.addOns.coolDown,
            includesCore: settings.addOns.coreWork,
            includesMobility: settings.addOns.mobilityFlexibility
        )
    }

    /// Generates an appropriate prescription for an exercise based on difficulty and workout structure.
    private func generatePrescription(
        for exercise: Exercise,
        difficulty: DifficultyLevel,
        structure: WorkoutStructure
    ) -> Prescription {

        // Start with the exercise's default prescription
        var prescription = exercise.defaultPrescription

        // Adjust based on difficulty
        switch difficulty {
        case .beginner:
            prescription.sets = min(prescription.sets ?? 2, 2)
            if let reps = prescription.reps {
                prescription.reps = max(reps - 2, 5)
            }
            prescription.intensity = "light"
            prescription.rest = max(prescription.rest ?? 60, 60)

        case .intermediate:
            prescription.sets = prescription.sets ?? 3
            prescription.intensity = "moderate"
            prescription.rest = prescription.rest ?? 45

        case .advanced:
            prescription.sets = (prescription.sets ?? 3) + 1
            if let reps = prescription.reps {
                prescription.reps = reps + 2
            }
            prescription.intensity = "high"
            prescription.rest = min(prescription.rest ?? 30, 30)

        case .elite:
            prescription.sets = (prescription.sets ?? 3) + 2
            if let reps = prescription.reps {
                prescription.reps = reps + 4
            }
            prescription.intensity = "maximum"
            prescription.rest = min(prescription.rest ?? 20, 20)
        }

        // Adjust for cardio exercises
        if exercise.category == .cardio {
            prescription.duration = prescription.duration ?? structure.exerciseTime
            prescription.sets = nil
            prescription.reps = nil
        }

        return prescription
    }

    // MARK: - Randomization with Constraints

    /// Applies sensible constraints to randomized settings.
    private func applyRandomizationConstraints(to settings: WorkoutGeneratorSettings) -> WorkoutGeneratorSettings {
        var constrained = settings

        // Pool location should use environmental goal type
        if constrained.location == .pool {
            constrained.goalType = .environmental
        }

        // Environmental workouts should have simpler structure
        if constrained.goalType == .environmental {
            constrained.exercisesPerRound = min(constrained.exercisesPerRound, 4)
            constrained.totalRounds = min(constrained.totalRounds, 2)
        }

        // Beginners should have more rest
        if constrained.difficulty == .beginner {
            constrained.restBetweenExercises = max(constrained.restBetweenExercises, 30)
            constrained.restBetweenRounds = max(constrained.restBetweenRounds, 60)
        }

        // Elite should have shorter rest
        if constrained.difficulty == .elite {
            constrained.restBetweenExercises = min(constrained.restBetweenExercises, 30)
        }

        // Longer workouts should have more rounds
        if constrained.lengthMinutes >= 60 && constrained.totalRounds < 2 {
            constrained.totalRounds = 2
        }

        // Short workouts should have fewer exercises
        if constrained.lengthMinutes <= 15 {
            constrained.exercisesPerRound = min(constrained.exercisesPerRound, 4)
            constrained.totalRounds = 1
        }

        return constrained
    }

    /// Generates a descriptive workout name based on goal and difficulty.
    private func generateWorkoutName(goalType: WorkoutGoalType, difficulty: DifficultyLevel) -> String {
        let prefixes: [WorkoutGoalType: [String]] = [
            .upperBody: ["Upper Power", "Push & Pull", "Arm Burner", "Shoulder Sculpt", "Upper Strength"],
            .lowerBody: ["Leg Day", "Lower Power", "Glute Builder", "Quad Crusher", "Lower Strength"],
            .fullBody: ["Total Body", "Full Body Blast", "Complete Workout", "Head to Toe", "All-Around Fit"],
            .cardio: ["Cardio Burn", "Heart Pumper", "Sweat Session", "Cardio Challenge", "Endurance Builder"],
            .environmental: ["Outdoor Flow", "Nature Workout", "Open Air Session", "Environmental Fit"]
        ]

        let suffixes: [DifficultyLevel: [String]] = [
            .beginner: ["Foundation", "Basics", "Starter"],
            .intermediate: ["Builder", "Progress", "Challenge"],
            .advanced: ["Extreme", "Intense", "Power"],
            .elite: ["Ultimate", "Beast Mode", "Maximum"]
        ]

        let prefix = prefixes[goalType]?.randomElement() ?? "Workout"
        let suffix = suffixes[difficulty]?.randomElement() ?? ""

        return suffix.isEmpty ? prefix : "\(prefix) - \(suffix)"
    }

    // MARK: - Workout History Management

    /// Saves a workout to history.
    func saveWorkout(_ workout: Workout) async throws {
        isLoading = true
        defer { isLoading = false }

        // Update the workout timestamp
        var savedWorkout = workout
        savedWorkout.updatedAt = Date()

        // Check if workout already exists (update vs insert)
        if let existingIndex = workoutHistory.firstIndex(where: { $0.id == workout.id }) {
            workoutHistory[existingIndex] = savedWorkout
        } else {
            workoutHistory.insert(savedWorkout, at: 0)
        }

        // Trim history if needed
        if workoutHistory.count > maxHistoryCount {
            workoutHistory = Array(workoutHistory.prefix(maxHistoryCount))
        }

        // Persist to storage
        persistWorkoutHistory()
    }

    /// Loads workout history from persistent storage.
    func loadWorkoutHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([Workout].self, from: data) else {
            workoutHistory = []
            return
        }
        workoutHistory = history
    }

    /// Persists workout history to storage.
    private func persistWorkoutHistory() {
        if let data = try? JSONEncoder().encode(workoutHistory) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    /// Fetches a workout by ID from history.
    func fetchWorkout(by id: String) async -> Workout? {
        return workoutHistory.first { $0.id == id }
    }

    /// Fetches workouts for a specific date.
    func fetchWorkouts(for date: Date) async -> [Workout] {
        let calendar = Calendar.current
        return workoutHistory.filter { workout in
            guard let scheduledDate = workout.scheduledDate else { return false }
            return calendar.isDate(scheduledDate, inSameDayAs: date)
        }
    }

    /// Fetches completed workouts.
    func fetchCompletedWorkouts() async -> [Workout] {
        return workoutHistory.filter { $0.isCompleted }
    }

    /// Fetches upcoming scheduled workouts.
    func fetchUpcomingWorkouts() async -> [Workout] {
        let now = Date()
        return workoutHistory
            .filter { workout in
                guard let scheduledDate = workout.scheduledDate else { return false }
                return scheduledDate > now && !workout.isCompleted
            }
            .sorted { ($0.scheduledDate ?? .distantFuture) < ($1.scheduledDate ?? .distantFuture) }
    }

    /// Deletes a workout from history.
    func deleteWorkout(_ workout: Workout) async throws {
        workoutHistory.removeAll { $0.id == workout.id }
        persistWorkoutHistory()
    }

    /// Marks a workout as complete.
    func completeWorkout(_ workout: Workout) async throws {
        guard let index = workoutHistory.firstIndex(where: { $0.id == workout.id }) else {
            throw WorkoutServiceError.workoutNotFound
        }

        var completed = workout
        completed.completedAt = Date()
        completed.updatedAt = Date()

        workoutHistory[index] = completed
        persistWorkoutHistory()
    }

    /// Marks an individual exercise as complete.
    func completeExercise(exerciseId: String, in workoutId: String) async throws {
        guard let workoutIndex = workoutHistory.firstIndex(where: { $0.id == workoutId }) else {
            throw WorkoutServiceError.workoutNotFound
        }

        var workout = workoutHistory[workoutIndex]
        guard let exerciseIndex = workout.exercises.firstIndex(where: { $0.id == exerciseId }) else {
            throw WorkoutServiceError.exerciseNotFound
        }

        workout.exercises[exerciseIndex].isCompleted = true
        workout.exercises[exerciseIndex].completedAt = Date()
        workout.updatedAt = Date()

        // Check if all exercises are complete
        if workout.exercises.allSatisfy({ $0.isCompleted }) {
            workout.completedAt = Date()
        }

        workoutHistory[workoutIndex] = workout
        persistWorkoutHistory()
    }

    /// Clears all workout history.
    func clearHistory() async {
        workoutHistory = []
        UserDefaults.standard.removeObject(forKey: historyKey)
    }

    // MARK: - Statistics

    /// Returns workout statistics for the user.
    func getWorkoutStatistics() async -> WorkoutStatistics {
        let completed = workoutHistory.filter { $0.isCompleted }
        let totalMinutes = completed.reduce(0) { $0 + $1.lengthMinutes }
        let totalExercises = completed.reduce(0) { $0 + $1.exercises.count }

        // Calculate streak
        let streak = calculateCurrentStreak()

        // Most common goal type
        let goalCounts = Dictionary(grouping: completed, by: { $0.goalType })
            .mapValues { $0.count }
        let favoriteGoal = goalCounts.max(by: { $0.value < $1.value })?.key

        return WorkoutStatistics(
            totalWorkouts: completed.count,
            totalMinutes: totalMinutes,
            totalExercises: totalExercises,
            currentStreak: streak,
            favoriteGoalType: favoriteGoal
        )
    }

    /// Calculates the current workout streak (consecutive days with workouts).
    private func calculateCurrentStreak() -> Int {
        let calendar = Calendar.current
        let completedDates = Set(
            workoutHistory
                .compactMap { $0.completedAt }
                .map { calendar.startOfDay(for: $0) }
        )

        guard !completedDates.isEmpty else { return 0 }

        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        // Check if today has a workout, if not start from yesterday
        if !completedDates.contains(currentDate) {
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }

        while completedDates.contains(currentDate) {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
        }

        return streak
    }

    // MARK: - Exercise Database

    /// Loads the exercise database. In production, this would fetch from an API.
    private func loadExerciseDatabase() {
        // Load sample exercises - in production, this would be an API call
        exerciseDatabase = Exercise.samples

        // Add more exercises for testing variety
        exerciseDatabase.append(contentsOf: generateAdditionalExercises())
    }

    /// Generates additional exercises for testing purposes.
    private func generateAdditionalExercises() -> [Exercise] {
        return [
            // Upper Body
            Exercise(
                id: "SH_STR_OVERHEAD_PRESS",
                name: "Overhead Press",
                videoAssetId: "SH_STR_OVERHEAD_PRESS",
                bodyRegion: .shoulders,
                muscleEmphasis: ["deltoids", "triceps"],
                category: .strengthening,
                equipment: [.dumbbells],
                level: .intermediate,
                cues: ["Stand tall, core engaged", "Press overhead", "Lower with control"],
                tempo: "2-1-2",
                defaultPrescription: .init(sets: 3, reps: 10, rest: 60),
                modifications: ["Seated variation"],
                exclusions: ["shoulder impingement"],
                safetyNotes: nil,
                approvalStatus: .approved,
                tags: ["shoulders", "press", "strength"],
                createdAt: Date(),
                updatedAt: Date()
            ),
            Exercise(
                id: "CH_STR_PUSHUP",
                name: "Push-Up",
                videoAssetId: "CH_STR_PUSHUP",
                bodyRegion: .chest,
                muscleEmphasis: ["pectorals", "triceps", "anterior deltoid"],
                category: .strengthening,
                equipment: [.none],
                level: .beginner,
                cues: ["Hands shoulder-width", "Body in straight line", "Lower chest to floor"],
                tempo: "2-1-2",
                defaultPrescription: .init(sets: 3, reps: 12, rest: 45),
                modifications: ["Knees down", "Incline push-up"],
                exclusions: [],
                safetyNotes: nil,
                approvalStatus: .approved,
                tags: ["chest", "push", "bodyweight"],
                createdAt: Date(),
                updatedAt: Date()
            ),
            Exercise(
                id: "AR_STR_BICEP_CURL",
                name: "Bicep Curl",
                videoAssetId: "AR_STR_BICEP_CURL",
                bodyRegion: .arms,
                muscleEmphasis: ["biceps"],
                category: .strengthening,
                equipment: [.dumbbells],
                level: .beginner,
                cues: ["Elbows at sides", "Curl to shoulder", "Lower slowly"],
                tempo: "2-1-3",
                defaultPrescription: .init(sets: 3, reps: 12, rest: 45),
                modifications: ["Hammer curl"],
                exclusions: [],
                safetyNotes: nil,
                approvalStatus: .approved,
                tags: ["arms", "biceps", "curl"],
                createdAt: Date(),
                updatedAt: Date()
            ),

            // Lower Body
            Exercise(
                id: "QD_STR_SQUAT",
                name: "Bodyweight Squat",
                videoAssetId: "QD_STR_SQUAT",
                bodyRegion: .quadriceps,
                muscleEmphasis: ["quadriceps", "glutes", "hamstrings"],
                category: .strengthening,
                equipment: [.none],
                level: .beginner,
                cues: ["Feet shoulder-width", "Sit back and down", "Knees track over toes"],
                tempo: "2-1-2",
                defaultPrescription: .init(sets: 3, reps: 15, rest: 45),
                modifications: ["Chair squat", "Goblet squat"],
                exclusions: [],
                safetyNotes: nil,
                approvalStatus: .approved,
                tags: ["legs", "squat", "bodyweight"],
                createdAt: Date(),
                updatedAt: Date()
            ),
            Exercise(
                id: "GL_STR_HIP_THRUST",
                name: "Hip Thrust",
                videoAssetId: "GL_STR_HIP_THRUST",
                bodyRegion: .glutes,
                muscleEmphasis: ["glutes", "hamstrings"],
                category: .strengthening,
                equipment: [.bench],
                level: .intermediate,
                cues: ["Upper back on bench", "Drive through heels", "Squeeze at top"],
                tempo: "2-2-2",
                defaultPrescription: .init(sets: 3, reps: 12, rest: 60),
                modifications: ["Glute bridge on floor"],
                exclusions: [],
                safetyNotes: nil,
                approvalStatus: .approved,
                tags: ["glutes", "hip", "strength"],
                createdAt: Date(),
                updatedAt: Date()
            ),
            Exercise(
                id: "HM_STR_DEADLIFT",
                name: "Romanian Deadlift",
                videoAssetId: "HM_STR_DEADLIFT",
                bodyRegion: .hamstrings,
                muscleEmphasis: ["hamstrings", "glutes", "lower back"],
                category: .strengthening,
                equipment: [.dumbbells],
                level: .intermediate,
                cues: ["Slight knee bend", "Hinge at hips", "Feel hamstring stretch"],
                tempo: "3-1-2",
                defaultPrescription: .init(sets: 3, reps: 10, rest: 60),
                modifications: ["Single leg variation"],
                exclusions: ["acute lower back pain"],
                safetyNotes: "Keep back neutral",
                approvalStatus: .approved,
                tags: ["hamstrings", "deadlift", "strength"],
                createdAt: Date(),
                updatedAt: Date()
            ),

            // Core
            Exercise(
                id: "CO_STR_PLANK",
                name: "Plank",
                videoAssetId: "CO_STR_PLANK",
                bodyRegion: .core,
                muscleEmphasis: ["rectus abdominis", "transverse abdominis", "obliques"],
                category: .stability,
                equipment: [.yogaMat],
                level: .beginner,
                cues: ["Forearms on ground", "Body in straight line", "Engage core"],
                tempo: nil,
                defaultPrescription: .init(sets: 3, duration: 30, rest: 45),
                modifications: ["Knees down"],
                exclusions: [],
                safetyNotes: nil,
                approvalStatus: .approved,
                tags: ["core", "plank", "stability"],
                createdAt: Date(),
                updatedAt: Date()
            ),
            Exercise(
                id: "CO_STR_CRUNCH",
                name: "Bicycle Crunch",
                videoAssetId: "CO_STR_CRUNCH",
                bodyRegion: .core,
                muscleEmphasis: ["obliques", "rectus abdominis"],
                category: .strengthening,
                equipment: [.yogaMat],
                level: .beginner,
                cues: ["Hands behind head", "Alternate elbow to knee", "Full rotation"],
                tempo: "controlled",
                defaultPrescription: .init(sets: 3, reps: 20, rest: 30),
                modifications: ["Slow tempo"],
                exclusions: ["neck pain"],
                safetyNotes: "Don't pull on neck",
                approvalStatus: .approved,
                tags: ["core", "abs", "crunch"],
                createdAt: Date(),
                updatedAt: Date()
            ),

            // Cardio
            Exercise(
                id: "FB_CD_JUMPING_JACKS",
                name: "Jumping Jacks",
                videoAssetId: "FB_CD_JUMPING_JACKS",
                bodyRegion: .fullBody,
                muscleEmphasis: ["cardiovascular"],
                category: .cardio,
                equipment: [.none],
                level: .beginner,
                cues: ["Jump feet wide", "Arms overhead", "Repeat continuously"],
                tempo: "fast",
                defaultPrescription: .init(duration: 60, intensity: "moderate"),
                modifications: ["Step jacks for low impact"],
                exclusions: [],
                safetyNotes: nil,
                approvalStatus: .approved,
                tags: ["cardio", "warmup", "full body"],
                createdAt: Date(),
                updatedAt: Date()
            ),
            Exercise(
                id: "FB_CD_BURPEE",
                name: "Burpee",
                videoAssetId: "FB_CD_BURPEE",
                bodyRegion: .fullBody,
                muscleEmphasis: ["full body", "cardiovascular"],
                category: .cardio,
                equipment: [.none],
                level: .advanced,
                cues: ["Squat down, hands to floor", "Jump feet back to plank", "Push-up, jump feet forward", "Jump up with arms overhead"],
                tempo: "fast",
                defaultPrescription: .init(sets: 3, reps: 10, intensity: "high", rest: 60),
                modifications: ["Step-back burpee", "No push-up"],
                exclusions: [],
                safetyNotes: nil,
                approvalStatus: .approved,
                tags: ["cardio", "full body", "hiit"],
                createdAt: Date(),
                updatedAt: Date()
            ),
            Exercise(
                id: "FB_CD_MOUNTAIN_CLIMBER",
                name: "Mountain Climbers",
                videoAssetId: "FB_CD_MOUNTAIN_CLIMBER",
                bodyRegion: .fullBody,
                muscleEmphasis: ["core", "hip flexors", "cardiovascular"],
                category: .cardio,
                equipment: [.none],
                level: .intermediate,
                cues: ["Start in plank", "Drive knees to chest alternating", "Keep hips down"],
                tempo: "fast",
                defaultPrescription: .init(duration: 45, intensity: "high"),
                modifications: ["Slow tempo"],
                exclusions: [],
                safetyNotes: nil,
                approvalStatus: .approved,
                tags: ["cardio", "core", "hiit"],
                createdAt: Date(),
                updatedAt: Date()
            ),

            // Warm-up exercises
            Exercise(
                id: "FB_WU_ARM_CIRCLES",
                name: "Arm Circles",
                videoAssetId: "FB_WU_ARM_CIRCLES",
                bodyRegion: .shoulders,
                muscleEmphasis: ["deltoids", "rotator cuff"],
                category: .warmUp,
                equipment: [.none],
                level: .beginner,
                cues: ["Arms extended", "Small circles, gradually larger", "Both directions"],
                tempo: "controlled",
                defaultPrescription: .init(duration: 30),
                modifications: [],
                exclusions: [],
                safetyNotes: nil,
                approvalStatus: .approved,
                tags: ["warmup", "shoulders", "mobility"],
                createdAt: Date(),
                updatedAt: Date()
            ),
            Exercise(
                id: "FB_WU_LEG_SWINGS",
                name: "Leg Swings",
                videoAssetId: "FB_WU_LEG_SWINGS",
                bodyRegion: .hips,
                muscleEmphasis: ["hip flexors", "hamstrings"],
                category: .warmUp,
                equipment: [.none],
                level: .beginner,
                cues: ["Hold wall for balance", "Swing leg front to back", "Increase range gradually"],
                tempo: "controlled",
                defaultPrescription: .init(sets: 1, reps: 15),
                modifications: [],
                exclusions: [],
                safetyNotes: nil,
                approvalStatus: .approved,
                tags: ["warmup", "hips", "dynamic"],
                createdAt: Date(),
                updatedAt: Date()
            ),

            // Cool-down exercises
            Exercise(
                id: "FB_CD_CHILDS_POSE",
                name: "Child's Pose",
                videoAssetId: "FB_CD_CHILDS_POSE",
                bodyRegion: .lowerBack,
                muscleEmphasis: ["lower back", "hips", "shoulders"],
                category: .coolDown,
                equipment: [.yogaMat],
                level: .beginner,
                cues: ["Knees wide, big toes together", "Sit back on heels", "Arms extended, forehead down"],
                tempo: nil,
                defaultPrescription: .init(duration: 60),
                modifications: ["Pad knees"],
                exclusions: [],
                safetyNotes: nil,
                approvalStatus: .approved,
                tags: ["cooldown", "stretch", "recovery"],
                createdAt: Date(),
                updatedAt: Date()
            ),
            Exercise(
                id: "FB_CD_HAMSTRING_STRETCH",
                name: "Seated Hamstring Stretch",
                videoAssetId: "FB_CD_HAMSTRING_STRETCH",
                bodyRegion: .hamstrings,
                muscleEmphasis: ["hamstrings"],
                category: .stretching,
                equipment: [.yogaMat],
                level: .beginner,
                cues: ["One leg extended", "Hinge at hips", "Reach toward toes"],
                tempo: nil,
                defaultPrescription: .init(sets: 1, duration: 30),
                modifications: ["Use strap"],
                exclusions: [],
                safetyNotes: "Don't bounce",
                approvalStatus: .approved,
                tags: ["stretch", "hamstrings", "cooldown"],
                createdAt: Date(),
                updatedAt: Date()
            )
        ]
    }

    /// Adds exercises to the database. Used for testing or loading from API.
    func addExercises(_ exercises: [Exercise]) {
        exerciseDatabase.append(contentsOf: exercises)
    }

    /// Clears and reloads the exercise database.
    func reloadExerciseDatabase() async {
        exerciseDatabase = []
        loadExerciseDatabase()
    }
}

// MARK: - Supporting Types

/// Represents the calculated structure of a workout.
struct WorkoutStructure {
    let totalDuration: Int           // minutes
    let exerciseTime: Int            // seconds per exercise
    let includesWarmUp: Bool
    let includesCoolDown: Bool
    let includesCore: Bool
    let includesMobility: Bool
}

/// Statistics about user's workout history.
struct WorkoutStatistics: Codable {
    let totalWorkouts: Int
    let totalMinutes: Int
    let totalExercises: Int
    let currentStreak: Int
    let favoriteGoalType: WorkoutGoalType?

    var formattedTotalTime: String {
        if totalMinutes >= 60 {
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours) hours"
        }
        return "\(totalMinutes) min"
    }
}

// MARK: - Errors

/// Errors that can occur in the WorkoutService.
enum WorkoutServiceError: LocalizedError {
    case insufficientExercises(required: Int, available: Int)
    case workoutNotFound
    case exerciseNotFound
    case invalidSettings
    case persistenceError
    case networkError

    var errorDescription: String? {
        switch self {
        case .insufficientExercises(let required, let available):
            return "Not enough exercises available. Required: \(required), Available: \(available). Try adjusting your filters."
        case .workoutNotFound:
            return "Workout not found in history."
        case .exerciseNotFound:
            return "Exercise not found in workout."
        case .invalidSettings:
            return "Invalid workout settings. Please check your configuration."
        case .persistenceError:
            return "Failed to save workout. Please try again."
        case .networkError:
            return "Network error. Please check your connection."
        }
    }
}

// MARK: - Preview Support

extension WorkoutService {
    /// Creates a preview instance with sample data.
    static var preview: WorkoutService {
        let service = WorkoutService()
        // Add sample workouts to history for preview
        service.workoutHistory = [Workout.sample]
        return service
    }
}
