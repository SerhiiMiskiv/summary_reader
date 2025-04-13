//
//  ChapterFeature.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 13.04.2025.
//

import Foundation
import ComposableArchitecture

@Reducer
struct ChapterPlayerFeature {
    
    @ObservableState
    struct State: Equatable {
        let chapter: Chapter
        var isPlaying: Bool
        var playbackTime: TimeInterval = 0
        var duration: TimeInterval = 0
        var playbackRate: Double = 1.0
    }
    
    enum Action {
        case playTapped
        case pauseTapped
        case stopTapped
        case progressUpdated(TimeInterval)
        case setRate(Double)
    }
    
    @Dependency(\.audioPlayer) var audioPlayer
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .playTapped:
                state.isPlaying = true
                return .run { [url = state.chapter.audioFile] send in
                    guard let url = Bundle.main.url(
                        forResource: url,
                        withExtension: nil
                    ) else {
                        return
                    }
                    
                    do {
                        try await audioPlayer.play(url)
                    } catch {
                        print("Failed to play audio:", error)
                        return
                    }
                    
                    for await time in audioPlayer.observeProgress() {
                        await send(.progressUpdated(time))
                    }
                }
                
            case .pauseTapped:
                state.isPlaying = false
                audioPlayer.pause()
                return .none
                
            case .stopTapped:
                state.isPlaying = false
                state.playbackTime = 0
                audioPlayer.stop()
                return .none
                
            case let .progressUpdated(time):
                state.playbackTime = time
                return .none
                
            case let .setRate(rate):
                state.playbackRate = rate
                return .run { _ in
                    audioPlayer.setRate(rate)
                }
            }
        }
    }
}
