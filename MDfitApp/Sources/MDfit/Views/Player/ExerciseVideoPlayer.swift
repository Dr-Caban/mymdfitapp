//
//  ExerciseVideoPlayer.swift
//  MDfit
//
//  Native video player with Picture-in-Picture and AirPlay support
//

import SwiftUI
import AVKit
import AVFoundation

// MARK: - Exercise Video Player
struct ExerciseVideoPlayer: View {
    @StateObject private var viewModel = VideoPlayerViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var isFullScreen: Bool = false
    @State private var orientation: UIDeviceOrientation = UIDevice.current.orientation

    let videoURL: URL
    let title: String
    let chapters: [VideoChapter]
    let artwork: UIImage?

    init(
        videoURL: URL,
        title: String,
        chapters: [VideoChapter] = [],
        artwork: UIImage? = nil
    ) {
        self.videoURL = videoURL
        self.title = title
        self.chapters = chapters
        self.artwork = artwork
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()

                // Video Player Layer
                if let player = viewModel.player {
                    VideoPlayerLayerView(
                        player: player,
                        videoGravity: .resizeAspect,
                        onLayerReady: { layer in
                            viewModel.setupPictureInPicture(playerLayer: layer)
                        }
                    )
                    .ignoresSafeArea(edges: isFullScreen ? .all : [])
                }

                // Controls Overlay
                VideoPlayerControls(
                    viewModel: viewModel,
                    isFullScreen: $isFullScreen,
                    onClose: {
                        dismiss()
                    }
                )
                .ignoresSafeArea(edges: isFullScreen ? .all : [])

                // Error State
                if case .error(let message) = viewModel.playerState {
                    errorView(message: message)
                }
            }
            .onAppear {
                setupPlayer()
            }
            .onDisappear {
                // Player cleanup handled by ViewModel deinit
            }
            .onChange(of: isFullScreen) { newValue in
                updateOrientation(fullscreen: newValue)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                handleOrientationChange()
            }
            .statusBar(hidden: isFullScreen)
            .persistentSystemOverlays(isFullScreen ? .hidden : .automatic)
        }
    }

    // MARK: - Setup
    private func setupPlayer() {
        viewModel.loadVideo(url: videoURL, title: title, chapters: chapters)
        if let artwork = artwork {
            viewModel.videoArtwork = artwork
        }
    }

    // MARK: - Orientation Handling
    private func updateOrientation(fullscreen: Bool) {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        if fullscreen {
            windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
        } else {
            windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        }
    }

    private func handleOrientationChange() {
        let currentOrientation = UIDevice.current.orientation
        if currentOrientation.isLandscape && !isFullScreen {
            isFullScreen = true
        } else if currentOrientation.isPortrait && isFullScreen {
            isFullScreen = false
        }
    }

    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.mdGold)

            Text("Playback Error")
                .font(.headline)
                .foregroundColor(.white)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: {
                viewModel.loadVideo(url: videoURL, title: title, chapters: chapters)
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.mdGold)
                .cornerRadius(24)
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
    }
}

// MARK: - Video Player Layer View (UIKit Wrapper)
struct VideoPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer
    let videoGravity: AVLayerVideoGravity
    let onLayerReady: (AVPlayerLayer) -> Void

    func makeUIView(context: Context) -> PlayerLayerUIView {
        let view = PlayerLayerUIView()
        view.player = player
        view.playerLayer.videoGravity = videoGravity
        view.backgroundColor = .black

        // Notify when layer is ready for PiP setup
        DispatchQueue.main.async {
            onLayerReady(view.playerLayer)
        }

        return view
    }

    func updateUIView(_ uiView: PlayerLayerUIView, context: Context) {
        uiView.player = player
        uiView.playerLayer.videoGravity = videoGravity
    }
}

// MARK: - Player Layer UIView
class PlayerLayerUIView: UIView {
    override class var layerClass: AnyClass {
        AVPlayerLayer.self
    }

    var playerLayer: AVPlayerLayer {
        layer as! AVPlayerLayer
    }

    var player: AVPlayer? {
        get { playerLayer.player }
        set { playerLayer.player = newValue }
    }
}

// MARK: - Mini Player View (for PiP-like inline display)
struct MiniVideoPlayer: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    let onExpand: () -> Void
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Video Thumbnail/Preview
            ZStack {
                if let player = viewModel.player {
                    VideoPlayerLayerView(
                        player: player,
                        videoGravity: .resizeAspectFill,
                        onLayerReady: { _ in }
                    )
                } else {
                    Rectangle()
                        .fill(Color(white: 0.2))
                }

                // Play state overlay
                if viewModel.playerState != .playing {
                    Color.black.opacity(0.4)

                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 20))
                }
            }
            .frame(width: 120, height: 68)
            .cornerRadius(8)
            .onTapGesture {
                viewModel.togglePlayPause()
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.videoTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)

                // Progress
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .mdGold))
                    .frame(height: 2)

                Text("\(viewModel.formatTime(viewModel.currentTime)) / \(viewModel.formatTime(viewModel.duration))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.gray)
            }

            Spacer()

            // Controls
            VStack(spacing: 8) {
                Button(action: onExpand) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                }

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .frame(width: 32, height: 32)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.1))
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -4)
        )
        .padding(.horizontal, 8)
    }
}

// MARK: - Exercise Video Player Sheet Modifier
extension View {
    func exerciseVideoPlayer(
        isPresented: Binding<Bool>,
        videoURL: URL?,
        title: String,
        chapters: [VideoChapter] = [],
        artwork: UIImage? = nil
    ) -> some View {
        self.fullScreenCover(isPresented: isPresented) {
            if let url = videoURL {
                ExerciseVideoPlayer(
                    videoURL: url,
                    title: title,
                    chapters: chapters,
                    artwork: artwork
                )
            }
        }
    }
}

// MARK: - Sample Chapter Data (for testing)
extension VideoChapter {
    static var sampleChapters: [VideoChapter] {
        [
            VideoChapter(title: "Warm Up", startTime: 0, endTime: 120),
            VideoChapter(title: "Stretching", startTime: 120, endTime: 300),
            VideoChapter(title: "Main Workout", startTime: 300, endTime: 900),
            VideoChapter(title: "Cool Down", startTime: 900, endTime: 1080),
            VideoChapter(title: "Recovery Tips", startTime: 1080, endTime: 1200)
        ]
    }
}

// MARK: - Preview
#if os(iOS)
#Preview {
    ExerciseVideoPlayer(
        videoURL: URL(string: "https://example.com/workout.mp4")!,
        title: "Full Body Strength Training",
        chapters: VideoChapter.sampleChapters
    )
}
#endif
