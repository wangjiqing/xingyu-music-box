import Foundation
import MediaPlayer
#if os(iOS)
import UIKit
#endif

@MainActor
final class RemoteCommandManager {
    static let shared = RemoteCommandManager()

    private var commandTargets: [Any] = []
    private var isConfigured = false

    private init() {}

    func setup(
        onPlay: @escaping @MainActor () -> Void,
        onPause: @escaping @MainActor () -> Void,
        onTogglePlayPause: @escaping @MainActor () -> Void,
        onNext: @escaping @MainActor () -> Void,
        onPrevious: @escaping @MainActor () -> Void,
        onSeek: @escaping @MainActor (TimeInterval) -> Void
    ) {
        guard !isConfigured else {
            activateTransportCommands()
            return
        }

        removeTargets()
        activateTransportCommands()
        disableUnsupportedCommands()

        let commandCenter = MPRemoteCommandCenter.shared()
        commandTargets = [
            commandCenter.playCommand.addTarget { _ in
                Task { @MainActor in onPlay() }
                return .success
            },
            commandCenter.pauseCommand.addTarget { _ in
                Task { @MainActor in onPause() }
                return .success
            },
            commandCenter.togglePlayPauseCommand.addTarget { _ in
                Task { @MainActor in onTogglePlayPause() }
                return .success
            },
            commandCenter.nextTrackCommand.addTarget { _ in
                Task { @MainActor in onNext() }
                return .success
            },
            commandCenter.previousTrackCommand.addTarget { _ in
                Task { @MainActor in onPrevious() }
                return .success
            },
            commandCenter.changePlaybackPositionCommand.addTarget { event in
                guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                    return .commandFailed
                }
                Task { @MainActor in onSeek(event.positionTime) }
                return .success
            }
        ]
        isConfigured = true
    }

    func activateTransportCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.isEnabled = true
    }

    func beginReceivingRemoteControlEvents() {
        #if os(iOS)
        UIApplication.shared.beginReceivingRemoteControlEvents()
        #endif
        activateTransportCommands()
        disableUnsupportedCommands()
    }

    func removeTargets() {
        let commandCenter = MPRemoteCommandCenter.shared()
        for target in commandTargets {
            commandCenter.playCommand.removeTarget(target)
            commandCenter.pauseCommand.removeTarget(target)
            commandCenter.togglePlayPauseCommand.removeTarget(target)
            commandCenter.nextTrackCommand.removeTarget(target)
            commandCenter.previousTrackCommand.removeTarget(target)
            commandCenter.changePlaybackPositionCommand.removeTarget(target)
        }
        commandTargets = []
        isConfigured = false
    }

    private func disableUnsupportedCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.stopCommand.isEnabled = false
        commandCenter.seekForwardCommand.isEnabled = false
        commandCenter.seekBackwardCommand.isEnabled = false
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false
        commandCenter.ratingCommand.isEnabled = false
        commandCenter.likeCommand.isEnabled = false
        commandCenter.dislikeCommand.isEnabled = false
        commandCenter.bookmarkCommand.isEnabled = false
        commandCenter.changePlaybackRateCommand.isEnabled = false
        commandCenter.changeRepeatModeCommand.isEnabled = false
        commandCenter.changeShuffleModeCommand.isEnabled = false
    }
}
