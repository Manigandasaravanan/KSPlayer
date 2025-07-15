//
//  KSVideoPlayerViewBuilder.swift
//
//
//  Created by Ian Magallan Bosch on 17.03.24.
//

import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
enum KSVideoPlayerViewBuilder {
    @MainActor
    static func playbackControlView(config: KSVideoPlayer.Coordinator, spacing: CGFloat? = nil, isIPad: Bool = false) -> some View {
        HStack(spacing: spacing) {
            // Playback controls don't need spacers for visionOS, since the controls are laid out in a HStack.
            #if os(xrOS)
            backwardButton(config: config)
            playButton(config: config)
            forwardButton(config: config)
            #else
            Spacer()
            backwardButton(config: config, isIPad: isIPad)
            Spacer()
            playButton(config: config, isIPad: isIPad)
            Spacer()
            forwardButton(config: config, isIPad: isIPad)
            Spacer()
            #endif
        }
    }

    @MainActor
    static func contentModeButton(config: KSVideoPlayer.Coordinator, isIPad: Bool = false) -> some View {
        Button {
            config.isScaleAspectFill.toggle()
        } label: {
            Image(config.isScaleAspectFill ? "minimize-02" : "maximize-02", bundle: .module)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(Color.white)
                .font(.system(size: isIPad ? 24 : 14)) // Reduce icon size
                .padding(8)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.5)) // Black transparent background
                )
//            Image(systemName: config.isScaleAspectFill ? "rectangle.arrowtriangle.2.inward" : "rectangle.arrowtriangle.2.outward")
        }
    }

    @MainActor
    static func subtitleButton(config: KSVideoPlayer.Coordinator, isIPad: Bool = false) -> some View {
        MenuView(selection: Binding {
            config.subtitleModel.selectedSubtitleInfo?.subtitleID
        } set: { value in
            let info = config.subtitleModel.subtitleInfos.first { $0.subtitleID == value }
            config.subtitleModel.selectedSubtitleInfo = info
            if let info = info as? MediaPlayerTrack {
                // 因为图片字幕想要实时的显示，那就需要seek。所以需要走select track
                config.playerLayer?.player.select(track: info)
            }
        }) {
            Text("Off").tag(nil as String?)
            let uniqueSubtitles = Dictionary(
                grouping: config.subtitleModel.subtitleInfos,
                by: { $0.displayLanguageName }
            ).compactMap { $0.value.first }

            ForEach(uniqueSubtitles, id: \.subtitleID) { track in
                Text(track.displayLanguageName).tag(track.subtitleID as String?)
            }
        } label: {
            Image(systemName: "captions.bubble")
                .font(.system(size: isIPad ? 24 : 18)) // Reduce icon size
                .padding(8) // Adjust padding to keep the circle neat
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.5)) // Black transparent background
                )
        }
    }

    @MainActor
    static func playbackRateButton(playbackRate: Binding<Float>) -> some View {
        MenuView(selection: playbackRate) {
            ForEach([0.5, 1.0, 1.25, 1.5, 2.0] as [Float]) { value in
                // 需要有一个变量text。不然会自动帮忙加很多0
                let text = "\(value) x"
                Text(text).tag(value)
            }
        } label: {
            Image(systemName: "gauge.with.dots.needle.67percent")
        }
    }

    @MainActor
    static func titleView(title: String, config: KSVideoPlayer.Coordinator, isIPad: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(isIPad ? .title : .subheadline)
                .foregroundStyle(Color.white)
            ProgressView()
                .opacity(config.state == .buffering ? 1 : 0)
        }
    }

    @MainActor
    static func muteButton(config: KSVideoPlayer.Coordinator, isIPad: Bool = false) -> some View {
        Button {
            config.isMuted.toggle()
        } label: {
            Image(systemName: config.isMuted ? speakerDisabledSystemName : speakerSystemName)
                .font(.system(size: isIPad ? 24 : 18)) // Reduce icon size
                .padding(8) // Adjust padding to keep the circle neat
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.5)) // Black transparent background
                )
        }
//        .shadow(color: .black, radius: 1)
    }

    static func infoButton(showVideoSetting: Binding<Bool>) -> some View {
        Button {
            showVideoSetting.wrappedValue.toggle()
        } label: {
            Image(systemName: "info.circle.fill")
        }
        // iOS 模拟器加keyboardShortcut会导致KSVideoPlayer.Coordinator无法释放。真机不会有这个问题
        #if !os(tvOS)
        .keyboardShortcut("i", modifiers: [.command])
        #endif
    }
}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private extension KSVideoPlayerViewBuilder {
    static var playSystemName: String {
        #if os(xrOS)
        "play.fill"
        #else
        "play.fill"
        #endif
    }

    static var pauseSystemName: String {
        #if os(xrOS)
        "pause.fill"
        #else
        "pause.fill"
        #endif
    }

    static var speakerSystemName: String {
        #if os(xrOS)
        "speaker.fill"
        #else
        "speaker.wave.2.fill"
        #endif
    }

    static var speakerDisabledSystemName: String {
        #if os(xrOS)
        "speaker.slash.fill"
        #else
        "speaker.slash.fill"
        #endif
    }
    
    static var chromecastSystemName: String {
        #if os(xrOS)
        "chrome-cast"
        #else
        "chrome-cast"
        #endif
    }

    @MainActor
    @ViewBuilder
    static func backwardButton(config: KSVideoPlayer.Coordinator, isIPad: Bool = false) -> some View {
        if config.playerLayer?.player.seekable ?? false {
            Button {
                config.skip(interval: -15)
            } label: {
                if isIPad {
                    Image(systemName: "gobackward.15")
                        .font(.system(size: 48))
                } else {
                    Image(systemName: "gobackward.15")
                        .font(.largeTitle)
                }
            }
            #if !os(tvOS)
            .keyboardShortcut(.leftArrow, modifiers: .none)
            #endif
        }
    }

    @MainActor
    @ViewBuilder
    static func forwardButton(config: KSVideoPlayer.Coordinator, isIPad: Bool = false) -> some View {
        if config.playerLayer?.player.seekable ?? false {
            Button {
                config.skip(interval: 15)
            } label: {
                if isIPad {
                    Image(systemName: "goforward.15")
                        .font(.system(size: 48))
                } else {
                    Image(systemName: "goforward.15")
                        .font(.largeTitle)
                }
            }
            #if !os(tvOS)
            .keyboardShortcut(.rightArrow, modifiers: .none)
            #endif
        }
    }

    @MainActor
    static func playButton(config: KSVideoPlayer.Coordinator, isIPad: Bool = false) -> some View {
        Button {
            if config.state.isPlaying {
                config.playerLayer?.pause()
            } else {
                config.playerLayer?.play()
            }
        } label: {
            Image(systemName: config.state == .error ? "play.fill" : (config.state.isPlaying ? pauseSystemName : playSystemName))
                .font(.system(size: isIPad ? 76 : 44)) // Reduce icon size
//                .foregroundStyle(Color(red: 186, green: 255, blue: 42))
        }
        #if os(xrOS)
        .contentTransition(.symbolEffect(.replace))
        #endif
        #if !os(tvOS)
        .keyboardShortcut(.space, modifiers: .none)
        #endif
    }
}
