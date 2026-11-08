import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Live Activity Widget

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ExpandedLeadingView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ExpandedTrailingView(context: context)
                }
                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenterView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(context: context)
                }
            } compactLeading: {
                CompactLeadingView(context: context)
            } compactTrailing: {
                CompactTrailingView(context: context)
            } minimal: {
                MinimalView(context: context)
            }
        }
    }
}

// MARK: - Lock Screen / Banner View

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)

                Circle()
                    .trim(from: 0, to: context.state.progress)
                    .stroke(
                        LinearGradient(
                            colors: [.widgetGold, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text(context.state.exerciseProgress)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.workoutName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                Text(context.state.currentExerciseName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 12) {
                    if context.state.isResting {
                        Label("Rest", systemImage: "pause.circle.fill")
                            .foregroundColor(.widgetBlue)
                        if let restSeconds = context.state.restSecondsRemaining {
                            Text("\(restSeconds)s")
                                .foregroundColor(.widgetGold)
                        }
                    } else {
                        Text(context.state.setProgress)
                            .foregroundColor(.white.opacity(0.7))
                        if let reps = context.state.repsRemaining {
                            Text("\(reps) reps")
                                .foregroundColor(.widgetGold)
                        }
                    }
                }
                .font(.system(size: 12, weight: .medium))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(context.state.formattedTime)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                    Text("\(context.state.caloriesBurned)")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(.widgetGold)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [.widgetCharcoal, .widgetBlack],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .activityBackgroundTint(.widgetCharcoal)
    }
}

// MARK: - Dynamic Island: Expanded Views

struct ExpandedLeadingView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Image(systemName: goalIcon)
                .font(.system(size: 18))
                .foregroundColor(.widgetGold)

            Text(context.state.exerciseProgress)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    private var goalIcon: String {
        switch context.attributes.goalType.lowercased() {
        case "upper body", "upperbody":
            return "figure.arms.open"
        case "lower body", "lowerbody":
            return "figure.run"
        case "full body", "fullbody":
            return "figure.mixed.cardio"
        case "cardio":
            return "heart.fill"
        default:
            return "dumbbell.fill"
        }
    }
}

struct ExpandedTrailingView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(context.state.formattedTime)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.white)

            HStack(spacing: 3) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 9))
                Text("\(context.state.caloriesBurned)")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(.widgetGold)
        }
    }
}

struct ExpandedCenterView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        VStack(spacing: 2) {
            Text(context.state.currentExerciseName)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)

            if context.state.isResting {
                HStack(spacing: 6) {
                    Image(systemName: "pause.circle.fill")
                        .foregroundColor(.widgetBlue)
                    Text("Rest")
                        .foregroundColor(.white.opacity(0.8))
                    if let restSeconds = context.state.restSecondsRemaining {
                        Text("\(restSeconds)s")
                            .foregroundColor(.widgetGold)
                    }
                }
                .font(.system(size: 12, weight: .medium))
            } else {
                HStack(spacing: 8) {
                    Text(context.state.setProgress)
                        .foregroundColor(.white.opacity(0.7))
                    if let reps = context.state.repsRemaining {
                        Text("\(reps) reps remaining")
                            .foregroundColor(.widgetGold)
                    }
                }
                .font(.system(size: 12, weight: .medium))
            }
        }
    }
}

struct ExpandedBottomView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.2))
                    .frame(height: 6)

                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [.widgetGold, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * context.state.progress, height: 6)
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Dynamic Island: Compact Views

struct CompactLeadingView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: context.state.isResting ? "pause.circle.fill" : "dumbbell.fill")
                .font(.system(size: 12))
                .foregroundColor(context.state.isResting ? .widgetBlue : .widgetGold)

            Text(context.state.exerciseProgress)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

struct CompactTrailingView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        if context.state.isResting, let restSeconds = context.state.restSecondsRemaining {
            Text("\(restSeconds)s")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.widgetBlue)
        } else {
            Text(context.state.formattedTime)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.widgetGold)
        }
    }
}

// MARK: - Dynamic Island: Minimal View

struct MinimalView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: context.state.progress)
                .stroke(
                    LinearGradient(
                        colors: [.widgetGold, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Image(systemName: context.state.isResting ? "pause.fill" : "figure.run")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(context.state.isResting ? .widgetBlue : .widgetGold)
        }
    }
}

// MARK: - Live Activity Manager

@MainActor
class WorkoutLiveActivityManager: ObservableObject {
    static let shared = WorkoutLiveActivityManager()

    @Published private(set) var currentActivity: Activity<WorkoutActivityAttributes>?

    private init() {}

    func startWorkoutActivity(
        workoutId: String,
        workoutName: String,
        goalType: String,
        estimatedDuration: Int,
        totalExercises: Int,
        totalSets: Int
    ) async throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw LiveActivityError.notAuthorized
        }

        await endCurrentActivity()

        let attributes = WorkoutActivityAttributes(
            workoutId: workoutId,
            workoutName: workoutName,
            goalType: goalType,
            startTime: Date(),
            estimatedDurationMinutes: estimatedDuration
        )

        let initialState = WorkoutActivityAttributes.ContentState(
            currentExerciseName: "Starting...",
            currentExerciseIndex: 1,
            totalExercises: totalExercises,
            currentSet: 1,
            totalSets: totalSets,
            repsRemaining: nil,
            timerSeconds: nil,
            isResting: false,
            restSecondsRemaining: nil,
            elapsedSeconds: 0,
            caloriesBurned: 0
        )

        let content = ActivityContent(
            state: initialState,
            staleDate: nil
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            throw LiveActivityError.failedToStart(error)
        }
    }

    func updateActivity(with state: WorkoutActivityAttributes.ContentState) async {
        guard let activity = currentActivity else { return }

        let content = ActivityContent(
            state: state,
            staleDate: nil
        )

        await activity.update(content)
    }

    func endCurrentActivity(showSummary: Bool = true) async {
        guard let activity = currentActivity else { return }

        let finalState = activity.content.state

        if showSummary {
            let content = ActivityContent(
                state: finalState,
                staleDate: Date()
            )
            await activity.end(content, dismissalPolicy: .after(.now + 5))
        } else {
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        currentActivity = nil
    }

    func updateExercise(
        name: String,
        index: Int,
        set: Int,
        reps: Int?,
        elapsedSeconds: Int,
        calories: Int
    ) async {
        guard let activity = currentActivity else { return }

        let state = activity.content.state
        let newState = WorkoutActivityAttributes.ContentState(
            currentExerciseName: name,
            currentExerciseIndex: index,
            totalExercises: state.totalExercises,
            currentSet: set,
            totalSets: state.totalSets,
            repsRemaining: reps,
            timerSeconds: nil,
            isResting: false,
            restSecondsRemaining: nil,
            elapsedSeconds: elapsedSeconds,
            caloriesBurned: calories
        )

        await updateActivity(with: newState)
    }

    func startRest(seconds: Int, elapsedSeconds: Int, calories: Int) async {
        guard let activity = currentActivity else { return }

        let state = activity.content.state
        let newState = WorkoutActivityAttributes.ContentState(
            currentExerciseName: state.currentExerciseName,
            currentExerciseIndex: state.currentExerciseIndex,
            totalExercises: state.totalExercises,
            currentSet: state.currentSet,
            totalSets: state.totalSets,
            repsRemaining: nil,
            timerSeconds: nil,
            isResting: true,
            restSecondsRemaining: seconds,
            elapsedSeconds: elapsedSeconds,
            caloriesBurned: calories
        )

        await updateActivity(with: newState)
    }

    func updateRestCountdown(seconds: Int) async {
        guard let activity = currentActivity else { return }

        let state = activity.content.state
        let newState = WorkoutActivityAttributes.ContentState(
            currentExerciseName: state.currentExerciseName,
            currentExerciseIndex: state.currentExerciseIndex,
            totalExercises: state.totalExercises,
            currentSet: state.currentSet,
            totalSets: state.totalSets,
            repsRemaining: nil,
            timerSeconds: nil,
            isResting: true,
            restSecondsRemaining: seconds,
            elapsedSeconds: state.elapsedSeconds + 1,
            caloriesBurned: state.caloriesBurned
        )

        await updateActivity(with: newState)
    }
}

// MARK: - Errors

enum LiveActivityError: LocalizedError {
    case notAuthorized
    case failedToStart(Error)
    case noActiveActivity

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Live Activities are not enabled. Please enable them in Settings."
        case .failedToStart(let error):
            return "Failed to start Live Activity: \(error.localizedDescription)"
        case .noActiveActivity:
            return "No active workout Live Activity."
        }
    }
}
