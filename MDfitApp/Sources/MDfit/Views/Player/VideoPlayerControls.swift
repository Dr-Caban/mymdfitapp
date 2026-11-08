//
//  VideoPlayerControls.swift
//  MDfit
//
//  Custom video player controls matching MD Fit design
//

import SwiftUI
import AVKit

// Colour tokens (mdGold, mdBlue, ...) come from Resources/Theme.swift.

// MARK: - Video Player Controls
struct VideoPlayerControls: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    @Binding var isFullScreen: Bool
    let onClose: () -> Void

    @State private var isDraggingProgress: Bool = false
    @State private var dragProgress: Double = 0
    @State private var showSpeedPicker: Bool = false
    @State private var showChapterList: Bool = false

    private let controlsBackground = Color.black.opacity(0.6)
    private let buttonSize: CGFloat = 44
    private let iconSize: CGFloat = 24

    var body: some View {
        ZStack {
            // Tap to toggle controls
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.toggleControls()
                }

            if viewModel.showControls {
                VStack(spacing: 0) {
                    // Top Bar
                    topBar

                    Spacer()

                    // Center Controls
                    centerControls

                    Spacer()

                    // Bottom Bar
                    bottomBar
                }
                .transition(.opacity)
            }

            // Loading Indicator
            if viewModel.playerState == .loading || viewModel.playerState == .buffering {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .mdGold))
                    .scaleEffect(1.5)
            }

            // Speed Picker Overlay
            if showSpeedPicker {
                speedPickerOverlay
            }

            // Chapter List Overlay
            if showChapterList {
                chapterListOverlay
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.showControls)
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 16) {
            // Close Button
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: buttonSize, height: buttonSize)
                    .background(controlsBackground)
                    .clipShape(Circle())
            }

            // Video Title
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.videoTitle)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)

                if let chapter = viewModel.currentChapter {
                    Text(chapter.title)
                        .font(.caption)
                        .foregroundColor(.mdGold)
                        .lineLimit(1)
                }
            }

            Spacer()

            // AirPlay Button
            AirPlayButton()
                .frame(width: buttonSize, height: buttonSize)

            // PiP Button
            if viewModel.isPictureInPicturePossible {
                Button(action: {
                    viewModel.togglePictureInPicture()
                }) {
                    Image(systemName: viewModel.isPictureInPictureActive ? "pip.exit" : "pip.enter")
                        .font(.system(size: iconSize))
                        .foregroundColor(.white)
                        .frame(width: buttonSize, height: buttonSize)
                        .background(controlsBackground)
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.7), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100)
            .allowsHitTesting(false)
        )
    }

    // MARK: - Center Controls
    private var centerControls: some View {
        HStack(spacing: 60) {
            // Seek Backward
            Button(action: {
                viewModel.seekBackward()
            }) {
                ZStack {
                    Circle()
                        .fill(controlsBackground)
                        .frame(width: 56, height: 56)

                    VStack(spacing: 2) {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }

            // Play/Pause
            Button(action: {
                viewModel.togglePlayPause()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.mdGold)
                        .frame(width: 72, height: 72)
                        .shadow(color: .mdGold.opacity(0.5), radius: 12, x: 0, y: 4)

                    Image(systemName: playPauseIcon)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                }
            }

            // Seek Forward
            Button(action: {
                viewModel.seekForward()
            }) {
                ZStack {
                    Circle()
                        .fill(controlsBackground)
                        .frame(width: 56, height: 56)

                    VStack(spacing: 2) {
                        Image(systemName: "goforward.10")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }

    private var playPauseIcon: String {
        switch viewModel.playerState {
        case .playing:
            return "pause.fill"
        case .ended:
            return "arrow.clockwise"
        default:
            return "play.fill"
        }
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 12) {
            // Progress Bar with Chapter Markers
            progressBar

            // Bottom Controls Row
            HStack(spacing: 16) {
                // Time Display
                HStack(spacing: 4) {
                    Text(viewModel.formatTime(viewModel.currentTime))
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)

                    Text("/")
                        .font(.system(size: 13))
                        .foregroundColor(.gray)

                    Text(viewModel.formatTime(viewModel.duration))
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                }

                Spacer()

                // Chapters Button
                if !viewModel.chapters.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            showChapterList = true
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 14))
                            Text("Chapters")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(controlsBackground)
                        .cornerRadius(16)
                    }
                }

                // Speed Button
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        showSpeedPicker = true
                    }
                }) {
                    Text(viewModel.playbackSpeed.displayText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(controlsBackground)
                        .cornerRadius(16)
                }

                // Mute Button
                Button(action: {
                    viewModel.isMuted.toggle()
                }) {
                    Image(systemName: viewModel.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: buttonSize, height: buttonSize)
                }

                // Fullscreen Toggle
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isFullScreen.toggle()
                    }
                }) {
                    Image(systemName: isFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .frame(width: buttonSize, height: buttonSize)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 120)
            .allowsHitTesting(false)
        )
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        GeometryReader { geometry in
            let width = geometry.size.width - 32

            ZStack(alignment: .leading) {
                // Background Track
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)

                // Buffered Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.5))
                    .frame(width: width * viewModel.bufferedProgress, height: 4)

                // Played Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.mdGold)
                    .frame(width: width * currentProgress, height: 4)

                // Chapter Markers
                ForEach(viewModel.chapters) { chapter in
                    let position = chapter.startTime / max(viewModel.duration, 1)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 6, height: 6)
                        .offset(x: width * position - 3)
                }

                // Thumb
                Circle()
                    .fill(Color.mdGold)
                    .frame(width: isDraggingProgress ? 16 : 12, height: isDraggingProgress ? 16 : 12)
                    .shadow(color: .mdGold.opacity(0.5), radius: 4, x: 0, y: 2)
                    .offset(x: width * currentProgress - (isDraggingProgress ? 8 : 6))
                    .animation(.spring(response: 0.2), value: isDraggingProgress)
            }
            .frame(height: 20)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDraggingProgress = true
                        let progress = max(0, min(1, value.location.x / width))
                        dragProgress = progress
                        viewModel.userInteracted()
                    }
                    .onEnded { value in
                        let progress = max(0, min(1, value.location.x / width))
                        let seekTime = progress * viewModel.duration
                        viewModel.seek(to: seekTime)
                        isDraggingProgress = false
                    }
            )
        }
        .frame(height: 20)
        .padding(.horizontal, 16)
    }

    private var currentProgress: Double {
        isDraggingProgress ? dragProgress : viewModel.progress
    }

    // MARK: - Speed Picker Overlay
    private var speedPickerOverlay: some View {
        ZStack {
            // Dimmed Background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        showSpeedPicker = false
                    }
                }

            // Speed Options
            VStack(spacing: 0) {
                Text("Playback Speed")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 16)

                ForEach(PlaybackSpeed.allCases) { speed in
                    Button(action: {
                        viewModel.playbackSpeed = speed
                        withAnimation(.spring(response: 0.3)) {
                            showSpeedPicker = false
                        }
                    }) {
                        HStack {
                            Text(speed.displayText)
                                .font(.system(size: 18, weight: viewModel.playbackSpeed == speed ? .bold : .regular))
                                .foregroundColor(viewModel.playbackSpeed == speed ? .mdGold : .white)

                            Spacer()

                            if viewModel.playbackSpeed == speed {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.mdGold)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }

                    if speed != PlaybackSpeed.allCases.last {
                        Divider()
                            .background(Color.white.opacity(0.2))
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.15))
            )
            .padding(.horizontal, 40)
        }
        .transition(.opacity)
    }

    // MARK: - Chapter List Overlay
    private var chapterListOverlay: some View {
        ZStack {
            // Dimmed Background
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        showChapterList = false
                    }
                }

            // Chapter List
            VStack(spacing: 0) {
                HStack {
                    Text("Chapters")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            showChapterList = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                Divider()
                    .background(Color.white.opacity(0.2))

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.chapters) { chapter in
                            Button(action: {
                                viewModel.seekToChapter(chapter)
                                withAnimation(.spring(response: 0.3)) {
                                    showChapterList = false
                                }
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(chapter.title)
                                            .font(.system(size: 16, weight: viewModel.currentChapter?.id == chapter.id ? .semibold : .regular))
                                            .foregroundColor(viewModel.currentChapter?.id == chapter.id ? .mdGold : .white)
                                            .lineLimit(2)
                                            .multilineTextAlignment(.leading)

                                        Text(viewModel.formatTime(chapter.startTime))
                                            .font(.system(size: 13, design: .monospaced))
                                            .foregroundColor(.gray)
                                    }

                                    Spacer()

                                    if viewModel.currentChapter?.id == chapter.id {
                                        Image(systemName: "play.fill")
                                            .foregroundColor(.mdGold)
                                            .font(.system(size: 12))
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                            }

                            Divider()
                                .background(Color.white.opacity(0.1))
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.15))
            )
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
    }
}

// MARK: - AirPlay Button (UIKit Wrapper)
struct AirPlayButton: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let routePickerView = AVRoutePickerView()
        routePickerView.tintColor = .white
        routePickerView.activeTintColor = UIColor(Color.mdGold)
        routePickerView.prioritizesVideoDevices = true

        // Make the view transparent background
        routePickerView.backgroundColor = .clear

        return routePickerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

// MARK: - Preview
#if os(iOS)
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VideoPlayerControls(
            viewModel: VideoPlayerViewModel(),
            isFullScreen: .constant(false),
            onClose: {}
        )
    }
}
#endif
