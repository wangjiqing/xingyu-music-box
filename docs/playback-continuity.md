# Playback Continuity

## System Media Controls

`RemoteCommandManager` is the single registration point for `MPRemoteCommandCenter.shared()`.
It is owned by the player service/view-model layer, not by SwiftUI view lifetime. The manager guards registration with an internal configured flag, removes targets on teardown, and explicitly disables unsupported commands so the system does not surface controls that the app cannot honor.

Supported commands:

- play
- pause
- togglePlayPause
- nextTrack
- previousTrack
- changePlaybackPosition

`NowPlayingInfoManager` is the single updater for `MPNowPlayingInfoCenter.default().nowPlayingInfo`. iOS/iPadOS uses `Song` artwork lookup; macOS uses `MacTrackItem` metadata and embedded artwork data. Playback state, elapsed time, duration, title, artist, album, and artwork are refreshed when the current item changes, playback state changes, seeking completes, duration becomes known, or periodic progress advances.

## Interruption Recovery

iOS/iPadOS interruptions are handled by `AudioSessionManager` and `PlayerViewModel`.

State captured at interruption begin:

- whether playback was active before the interruption;
- current song id;
- current playback time;
- whether the user manually paused during the interruption;
- whether the user changed track or playback state during the interruption.

On interruption begin, the player pauses without treating it as a user pause. On interruption end, the audio session is reactivated and playback resumes only when all conditions hold:

- the player was playing before the interruption;
- the system interruption options include resume permission;
- the user did not manually pause;
- the user did not switch track or otherwise replace playback;
- the player item is still loaded and matches the saved song id.

This covers phone, FaceTime, WeChat voice/video, and Siri interruption paths through `AVAudioSession.interruptionNotification`. Route changes such as unplugging headphones are intentionally not collapsed into this same state machine.

## Playback Persistence

`PlaybackCheckpoint` and `PlaybackPersistence` own playback restore data. Views do not write playback persistence directly.

Persisted fields:

- current track stable id;
- fallback track info: source URL, title, artist, album;
- current playback time;
- queue snapshots and queue index;
- playback mode;
- save timestamp.

Save points:

- track changes;
- seek completion;
- play/pause and playback mode changes;
- app scene phase changes;
- macOS local-folder restore and progress ticks.

Restore happens only after the relevant library or queue is loaded. If the old song cannot be found, the app falls back silently to its normal default selection. Cold start restores the last selected item and position in a paused state; it never starts speaker playback automatically.

Progress bounds:

- negative or non-finite values become `0`;
- values at or beyond duration are clamped below duration, or reset to `0` for repeat-one;
- unknown durations are not treated as seek failures.

## Debug / Release Configuration Boundary

Release builds start with an empty Music Vault endpoint and no credentials. The local `OpenApiConfig.plist` injection script copies the ignored local config only for Debug builds and deletes the destination in Release.

macOS user configuration is read from shared Application Support first: `/Library/Application Support/XingyuMusicBox/OpenApiConfig.plist`. When that directory is not writable, saves fall back to `~/Library/Application Support/XingyuMusicBox/OpenApiConfig.plist`. The plist contains the endpoint and user-entered AK/SK so local ad-hoc test builds do not trigger Keychain permission prompts. Release builds still ship with an empty first-run configuration and no bundled credentials.

Release packages must not contain:

- real AK/SK;
- concrete internal IPs;
- developer home directories;
- bundled `OpenApiConfig.plist`.

## Test Matrix

- macOS Apple Silicon: AirPods click play/pause, keyboard media keys, Control Center play/pause/next/previous/seek, artwork and progress display.
- macOS windowing: menu bar "打开星语音乐盒" from background, hidden, minimized, and obscured states; repeated clicks should reuse the main window.
- iOS/iPadOS: phone call interruption resumes near the interrupted time when permitted; manual pause during interruption does not resume.
- iOS/iPadOS: WeChat voice/video interruption follows the same resume rules.
- All platforms: quit and relaunch restores last selected track and position paused.
- Release: delete app/container, install Release, settings page has empty credentials and endpoint; unpacked app search finds no real AK/SK, internal IP, or developer path.
