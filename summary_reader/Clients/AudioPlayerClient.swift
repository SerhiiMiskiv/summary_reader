//
//  AudioPlayerClient.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 13.04.2025.
//

import Foundation
import AVFoundation
import Combine
import ComposableArchitecture

// MARK: - Client

struct AudioPlayerClient {
    var play: @Sendable (_ url: URL) async throws -> Void
    var playWithoutReplacing: @Sendable () -> Void
    var pause: @Sendable () -> Void
    var stop: @Sendable () -> Void
    var seek: @Sendable (_ time: TimeInterval, _ rate: Double) -> Void
    var setRate: @Sendable (_ rate: Double) -> Void
    var observeProgress: @Sendable () -> AsyncStream<TimeInterval>
}

// MARK: Dependency Key

extension AudioPlayerClient: DependencyKey {
    static let liveValue: AudioPlayerClient = {
        let player = AVPlayer()
        let progressSubject = PassthroughSubject<TimeInterval, Never>()
        var timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: CMTime(
                seconds: 0.5,
                preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
                queue: .main
        ) { time in
            progressSubject.send(time.seconds)
        }

        return AudioPlayerClient(
            play: { url in
                let item = AVPlayerItem(url: url)
                player.replaceCurrentItem(with: item)
                player.play()
            },
            playWithoutReplacing: {
                player.play()
            },
            pause: {
                player.pause()
            },
            stop: {
                player.pause()
                player.replaceCurrentItem(with: nil)
            },
            seek: { time, rate in
                let cmTime = CMTime(seconds: time, preferredTimescale: 1)
                player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero) { _ in
                    player.rate = Float(rate)
                }
            },
            setRate: { rate in
                player.rate = Float(rate)
            },
            observeProgress: {
                AsyncStream { continuation in
                    let cancellable = progressSubject.sink { time in
                        continuation.yield(time)
                    }

                    continuation.onTermination = { @Sendable _ in
                        cancellable.cancel()
                    }
                }
            }
        )
    }()
}

// MARK: - Dependency Value

extension DependencyValues {
    var audioPlayer: AudioPlayerClient {
        get { self[AudioPlayerClient.self] }
        set { self[AudioPlayerClient.self] = newValue }
    }
}
