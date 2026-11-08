import Foundation
import HealthKit
import Combine

// MARK: - HealthKit Service

@MainActor
final class HealthKitService: NSObject, ObservableObject {
    static let shared = HealthKitService()

    // MARK: - Published Properties

    @Published private(set) var isAvailable = false
    @Published private(set) var isAuthorized = false
    @Published private(set) var isLoading = false

    // Today's Health Data
    @Published private(set) var todayStepCount: Int = 0
    @Published private(set) var todayActiveCalories: Double = 0
    @Published private(set) var todayWorkoutMinutes: Int = 0
    @Published private(set) var currentHeartRate: Double?
    @Published private(set) var restingHeartRate: Double?
    @Published private(set) var heartRateVariability: Double?

    // Workout Session
    @Published private(set) var isWorkoutSessionActive = false
    @Published private(set) var currentWorkoutDuration: TimeInterval = 0
    @Published private(set) var currentWorkoutCalories: Double = 0
    @Published private(set) var currentWorkoutHeartRate: Double?

    // MARK: - Private Properties

    private let healthStore = HKHealthStore()

    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private var workoutStartDate: Date?
    private var workoutTimer: Timer?
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var backgroundDeliveryEnabled = false

    // MARK: - Health Types

    private var readTypes: Set<HKObjectType> {
        var types: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
            HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
            HKObjectType.quantityType(forIdentifier: .distanceSwimming)!,
            HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!,
            HKObjectType.workoutType(),
            HKObjectType.activitySummaryType()
        ]

        if #available(iOS 16.0, *) {
            types.insert(HKObjectType.quantityType(forIdentifier: .runningPower)!)
            types.insert(HKObjectType.quantityType(forIdentifier: .runningSpeed)!)
        }

        return types
    }

    private var writeTypes: Set<HKSampleType> {
        [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
            HKObjectType.quantityType(forIdentifier: .distanceSwimming)!,
            HKObjectType.workoutType()
        ]
    }

    // MARK: - Initialization

    override private init() {
        super.init()
        isAvailable = HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        guard isAvailable else {
            print("[HealthKitService] HealthKit not available on this device")
            return false
        }

        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)

            let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
            let status = healthStore.authorizationStatus(for: stepType)

            await MainActor.run {
                isAuthorized = status == .sharingAuthorized
            }

            if isAuthorized {
                await refreshAllHealthData()
            }

            return isAuthorized
        } catch {
            print("[HealthKitService] Authorization failed: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        guard isAvailable else { return }

        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let status = healthStore.authorizationStatus(for: stepType)
        isAuthorized = status == .sharingAuthorized
    }

    // MARK: - Background Delivery

    func setupBackgroundDelivery() async throws {
        guard isAuthorized, !backgroundDeliveryEnabled else { return }

        let typesToObserve: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .activeEnergyBurned,
            .appleExerciseTime,
            .heartRate
        ]

        for identifier in typesToObserve {
            guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { continue }

            do {
                try await healthStore.enableBackgroundDelivery(for: type, frequency: .hourly)
            } catch {
                print("[HealthKitService] Failed to enable background delivery for \(identifier): \(error)")
            }
        }

        backgroundDeliveryEnabled = true
    }

    func handleBackgroundDelivery(for type: HKObjectType, completion: @escaping () -> Void) {
        Task {
            await refreshAllHealthData()
            completion()
        }
    }

    // MARK: - Reading Health Data

    func refreshAllHealthData() async {
        guard isAuthorized else { return }

        isLoading = true
        defer { isLoading = false }

        async let steps = fetchTodayStepCount()
        async let calories = fetchTodayActiveCalories()
        async let workoutMins = fetchTodayWorkoutMinutes()
        async let heartRate = fetchLatestHeartRate()
        async let restingHR = fetchRestingHeartRate()
        async let hrv = fetchHeartRateVariability()

        let (stepsResult, caloriesResult, workoutMinsResult, heartRateResult, restingHRResult, hrvResult) =
            await (steps, calories, workoutMins, heartRate, restingHR, hrv)

        todayStepCount = stepsResult
        todayActiveCalories = caloriesResult
        todayWorkoutMinutes = workoutMinsResult
        currentHeartRate = heartRateResult
        restingHeartRate = restingHRResult
        heartRateVariability = hrvResult
    }

    func fetchTodayStepCount() async -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }

        let predicate = createTodayPredicate()

        do {
            let statistics = try await fetchStatistics(for: stepType, predicate: predicate, options: .cumulativeSum)
            return Int(statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
        } catch {
            print("[HealthKitService] Failed to fetch step count: \(error)")
            return 0
        }
    }

    func fetchTodayActiveCalories() async -> Double {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }

        let predicate = createTodayPredicate()

        do {
            let statistics = try await fetchStatistics(for: calorieType, predicate: predicate, options: .cumulativeSum)
            return statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
        } catch {
            print("[HealthKitService] Failed to fetch active calories: \(error)")
            return 0
        }
    }

    func fetchTodayWorkoutMinutes() async -> Int {
        guard let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) else { return 0 }

        let predicate = createTodayPredicate()

        do {
            let statistics = try await fetchStatistics(for: exerciseType, predicate: predicate, options: .cumulativeSum)
            return Int(statistics?.sumQuantity()?.doubleValue(for: .minute()) ?? 0)
        } catch {
            print("[HealthKitService] Failed to fetch workout minutes: \(error)")
            return 0
        }
    }

    func fetchLatestHeartRate() async -> Double? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("[HealthKitService] Failed to fetch heart rate: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let heartRate = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                continuation.resume(returning: heartRate)
            }

            healthStore.execute(query)
        }
    }

    func fetchRestingHeartRate() async -> Double? {
        guard let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return nil }

        let predicate = createTodayPredicate()

        do {
            let statistics = try await fetchStatistics(for: restingHRType, predicate: predicate, options: .discreteAverage)
            return statistics?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
        } catch {
            print("[HealthKitService] Failed to fetch resting heart rate: \(error)")
            return nil
        }
    }

    func fetchHeartRateVariability() async -> Double? {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return nil }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("[HealthKitService] Failed to fetch HRV: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let hrv = sample.quantity.doubleValue(for: .secondUnit(with: .milli))
                continuation.resume(returning: hrv)
            }

            healthStore.execute(query)
        }
    }

    func fetchWeeklySummary() async -> WeeklyHealthSummary {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) else {
            return WeeklyHealthSummary()
        }

        async let steps = fetchStepCount(from: startDate, to: endDate)
        async let calories = fetchActiveCalories(from: startDate, to: endDate)
        async let workouts = fetchWorkouts(from: startDate, to: endDate)

        let (stepsResult, caloriesResult, workoutsResult) = await (steps, calories, workouts)

        let totalWorkoutMinutes = workoutsResult.reduce(0) { $0 + Int($1.duration / 60) }

        return WeeklyHealthSummary(
            totalSteps: stepsResult,
            totalActiveCalories: caloriesResult,
            totalWorkoutMinutes: totalWorkoutMinutes,
            workoutCount: workoutsResult.count,
            averageDailySteps: stepsResult / 7,
            averageDailyCalories: caloriesResult / 7
        )
    }

    func fetchStepCount(from startDate: Date, to endDate: Date) async -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return 0 }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        do {
            let statistics = try await fetchStatistics(for: stepType, predicate: predicate, options: .cumulativeSum)
            return Int(statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
        } catch {
            return 0
        }
    }

    func fetchActiveCalories(from startDate: Date, to endDate: Date) async -> Double {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return 0 }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        do {
            let statistics = try await fetchStatistics(for: calorieType, predicate: predicate, options: .cumulativeSum)
            return statistics?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
        } catch {
            return 0
        }
    }

    // MARK: - Workout Session Management

    @available(iOS 17.0, watchOS 10.0, *)
    func startWorkoutSession(for workout: Workout) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }

        guard !isWorkoutSessionActive else {
            throw HealthKitError.workoutAlreadyActive
        }

        let workoutType = mapWorkoutType(from: workout.goalType, location: workout.location)
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = mapLocationToHealthKit(workout.location)

        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder()

            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(
                healthStore: healthStore,
                workoutConfiguration: configuration
            )

            let startDate = Date()
            workoutSession?.startActivity(with: startDate)
            try await workoutBuilder?.beginCollection(at: startDate)

            workoutStartDate = startDate
            isWorkoutSessionActive = true
            currentWorkoutDuration = 0
            currentWorkoutCalories = 0

            startWorkoutTimer()
            startHeartRateMonitoring()

        } catch {
            throw HealthKitError.workoutSessionFailed(error)
        }
    }

    func pauseWorkoutSession() {
        workoutSession?.pause()
        stopWorkoutTimer()
    }

    func resumeWorkoutSession() {
        workoutSession?.resume()
        startWorkoutTimer()
    }

    func endWorkoutSession() async throws -> HKWorkout? {
        guard let session = workoutSession, let builder = workoutBuilder else {
            throw HealthKitError.noActiveWorkout
        }

        let endDate = Date()

        session.end()
        stopWorkoutTimer()
        stopHeartRateMonitoring()

        do {
            try await builder.endCollection(at: endDate)
            let finishedWorkout = try await builder.finishWorkout()

            workoutSession = nil
            workoutBuilder = nil
            workoutStartDate = nil
            isWorkoutSessionActive = false
            currentWorkoutDuration = 0
            currentWorkoutCalories = 0
            currentWorkoutHeartRate = nil

            await refreshAllHealthData()

            return finishedWorkout
        } catch {
            throw HealthKitError.workoutSaveFailed(error)
        }
    }

    func discardWorkoutSession() {
        workoutSession?.end()
        workoutBuilder?.discardWorkout()

        stopWorkoutTimer()
        stopHeartRateMonitoring()

        workoutSession = nil
        workoutBuilder = nil
        workoutStartDate = nil
        isWorkoutSessionActive = false
        currentWorkoutDuration = 0
        currentWorkoutCalories = 0
        currentWorkoutHeartRate = nil
    }

    // MARK: - Syncing Workouts to Apple Health

    func syncWorkoutToHealth(_ workout: Workout) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }

        guard let completedAt = workout.completedAt else {
            throw HealthKitError.invalidWorkoutData
        }

        let duration = TimeInterval(workout.lengthMinutes * 60)
        let startDate = completedAt.addingTimeInterval(-duration)
        let endDate = completedAt

        let workoutBuilder = HKWorkoutBuilder(
            healthStore: healthStore,
            configuration: HKWorkoutConfiguration(),
            device: .local()
        )

        do {
            try await workoutBuilder.beginCollection(at: startDate)

            let estimatedCalories = estimateCalories(for: workout)
            if estimatedCalories > 0 {
                let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
                let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: estimatedCalories)
                let energySample = HKQuantitySample(
                    type: energyType,
                    quantity: energyQuantity,
                    start: startDate,
                    end: endDate
                )
                try await workoutBuilder.addSamples([energySample])
            }

            try await workoutBuilder.endCollection(at: endDate)
            try await workoutBuilder.finishWorkout()

            await refreshAllHealthData()

        } catch {
            throw HealthKitError.workoutSyncFailed(error)
        }
    }

    func fetchWorkouts(from startDate: Date, to endDate: Date) async -> [HKWorkout] {
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    print("[HealthKitService] Failed to fetch workouts: \(error)")
                    continuation.resume(returning: [])
                    return
                }

                let workouts = samples as? [HKWorkout] ?? []
                continuation.resume(returning: workouts)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Private Helpers

    private func createTodayPredicate() -> NSPredicate {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        return HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
    }

    private func fetchStatistics(
        for quantityType: HKQuantityType,
        predicate: NSPredicate,
        options: HKStatisticsOptions
    ) async throws -> HKStatistics? {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: options
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: statistics)
            }

            healthStore.execute(query)
        }
    }

    private func mapWorkoutType(from goalType: WorkoutGoalType, location: WorkoutLocation) -> HKWorkoutActivityType {
        switch goalType {
        case .environmental:
            switch location {
            case .pool:
                return .swimming
            case .outdoor:
                return .running
            default:
                return .mixedCardio
            }
        case .cardio:
            return .mixedCardio
        case .upperBody, .lowerBody, .fullBody:
            return .functionalStrengthTraining
        }
    }

    private func mapLocationToHealthKit(_ location: WorkoutLocation) -> HKWorkoutSessionLocationType {
        switch location {
        case .outdoor, .pool:
            return .outdoor
        case .home, .gym, .custom:
            return .indoor
        }
    }

    private func estimateCalories(for workout: Workout) -> Double {
        let baseRate: Double
        switch workout.difficulty {
        case .beginner:
            baseRate = 5.0
        case .intermediate:
            baseRate = 7.0
        case .advanced:
            baseRate = 9.0
        case .elite:
            baseRate = 11.0
        }

        let typeMultiplier: Double
        switch workout.goalType {
        case .cardio, .environmental:
            typeMultiplier = 1.3
        case .fullBody:
            typeMultiplier = 1.1
        case .upperBody, .lowerBody:
            typeMultiplier = 1.0
        }

        return Double(workout.lengthMinutes) * baseRate * typeMultiplier
    }

    // MARK: - Workout Timer

    private func startWorkoutTimer() {
        stopWorkoutTimer()

        workoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let startDate = self.workoutStartDate else { return }
                self.currentWorkoutDuration = Date().timeIntervalSince(startDate)
            }
        }
    }

    private func stopWorkoutTimer() {
        workoutTimer?.invalidate()
        workoutTimer = nil
    }

    // MARK: - Heart Rate Monitoring

    private func startHeartRateMonitoring() {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)

        heartRateQuery = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, error in
            guard error == nil, let samples = samples as? [HKQuantitySample] else { return }
            self?.processHeartRateSamples(samples)
        }

        heartRateQuery?.updateHandler = { [weak self] _, samples, _, _, error in
            guard error == nil, let samples = samples as? [HKQuantitySample] else { return }
            self?.processHeartRateSamples(samples)
        }

        if let query = heartRateQuery {
            healthStore.execute(query)
        }
    }

    private func stopHeartRateMonitoring() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
    }

    private func processHeartRateSamples(_ samples: [HKQuantitySample]) {
        guard let latestSample = samples.last else { return }

        let heartRate = latestSample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))

        Task { @MainActor in
            self.currentWorkoutHeartRate = heartRate
        }
    }

    // MARK: - Internal Session Updates

    func updateWorkoutStatistics(calories: Double) {
        Task { @MainActor in
            self.currentWorkoutCalories = calories
        }
    }

    func handleSessionStateChange(_ state: HKWorkoutSessionState) {
        Task { @MainActor in
            switch state {
            case .running:
                self.isWorkoutSessionActive = true
            case .ended, .notStarted, .stopped:
                self.isWorkoutSessionActive = false
            case .paused, .prepared:
                break
            @unknown default:
                break
            }
        }
    }
}

// MARK: - Supporting Types

struct WeeklyHealthSummary {
    var totalSteps: Int = 0
    var totalActiveCalories: Double = 0
    var totalWorkoutMinutes: Int = 0
    var workoutCount: Int = 0
    var averageDailySteps: Int = 0
    var averageDailyCalories: Double = 0

    var formattedTotalCalories: String {
        String(format: "%.0f", totalActiveCalories)
    }

    var formattedTotalSteps: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: totalSteps)) ?? "\(totalSteps)"
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case authorizationFailed(Error)
    case queryFailed(Error)
    case workoutAlreadyActive
    case noActiveWorkout
    case workoutSessionFailed(Error)
    case workoutSaveFailed(Error)
    case workoutSyncFailed(Error)
    case invalidWorkoutData
    case backgroundDeliveryFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device."
        case .notAuthorized:
            return "Health data access not authorized. Please enable in Settings."
        case .authorizationFailed(let error):
            return "Failed to authorize HealthKit access: \(error.localizedDescription)"
        case .queryFailed(let error):
            return "Failed to query health data: \(error.localizedDescription)"
        case .workoutAlreadyActive:
            return "A workout session is already active."
        case .noActiveWorkout:
            return "No active workout session to end."
        case .workoutSessionFailed(let error):
            return "Workout session failed: \(error.localizedDescription)"
        case .workoutSaveFailed(let error):
            return "Failed to save workout: \(error.localizedDescription)"
        case .workoutSyncFailed(let error):
            return "Failed to sync workout to Apple Health: \(error.localizedDescription)"
        case .invalidWorkoutData:
            return "Invalid workout data. Ensure the workout is completed."
        case .backgroundDeliveryFailed(let error):
            return "Failed to enable background updates: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview Support

extension HealthKitService {
    static var preview: HealthKitService {
        let service = HealthKitService()
        service.isAuthorized = true
        service.todayStepCount = 8547
        service.todayActiveCalories = 342
        service.todayWorkoutMinutes = 45
        service.currentHeartRate = 72
        service.restingHeartRate = 58
        return service
    }
}
