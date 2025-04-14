//
//  ChapterFeature.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 13.04.2025.
//

import Foundation
import ComposableArchitecture
import AVFoundation

@Reducer
struct ChapterPlayerFeature {
    
    enum PlayerState: Equatable {
        case newlyAdded
        case playing
        case paused
        case stopped
    }
    
    @ObservableState
    struct State: Equatable {
        let chapters: [Chapter]
        var currentIndex: Int = 0
        var currentChapter: Chapter {
            chapters[currentIndex]
        }
        
        var playerState: PlayerState = .newlyAdded
        var isPlaying: Bool = false
        var playbackTime: TimeInterval = 0
        var duration: TimeInterval = 0
        var playbackRate: Double = 1.0
    }
    
    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case playTapped
        case calculateDuration
        case startPlaying
        case pauseTapped
        case playbackEnded
        case skipForwardTapped
        case skipBackwardTapped
        case seek(to: TimeInterval)
        case observeProgress
        case progressUpdated(TimeInterval)
        case durationLoaded(TimeInterval)
        case setRate(Double)
        case nextChapter
        case previousChapter
    }
    
    @Dependency(\.audioPlayer) var audioPlayer
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .playTapped:
                return .concatenate(
                    .send(.calculateDuration),
                    .send(.startPlaying),
                    .send(.observeProgress)
                )
                
            case .calculateDuration:
                let chapter = state.currentChapter
                
                return .run { send in
                    let asset = AVURLAsset(url: chapter.audioFileURL)
                    
                    do {
                        let cmDuration = try await asset.load(.duration)
                        await send(.durationLoaded(cmDuration.seconds))
                    } catch {
                        print("Failed to load duration: \(error)")
                        await send(.durationLoaded(0))
                    }
                }
                
            case .startPlaying:
                state.isPlaying = true
                let chapter = state.currentChapter
                let playerState = state.playerState
                
                let shouldReplaceItem = playerState == .newlyAdded || playerState == .stopped
                
                return .run { send in
                    if shouldReplaceItem {
                        do {
                            try await audioPlayer.play(chapter.audioFileURL)
                        } catch {
                            print("Failed to play audio:", error)
                            return
                        }
                    }
                    else {
                        audioPlayer.playWithoutReplacing()
                    }
                }
                
            case .pauseTapped:
                state.isPlaying = false
                state.playerState = .paused
                return .run { _ in audioPlayer.pause() }
                
            case let .progressUpdated(time):
                state.playbackTime = time
                return .none
                
            case let .durationLoaded(duration):
                state.duration = duration
                return .none
                
            case let .setRate(rate):
                state.playbackRate = rate
                return .run { _ in audioPlayer.setRate(rate) }
                
            case let .seek(to: position):
                state.playbackTime = position
                let rate = state.playbackRate
                return .run { _ in audioPlayer.seek(position, rate) }
                
            case .skipForwardTapped:
                let newTime = min(state.playbackTime + 10, state.duration)
                return .send(.seek(to: newTime))
                
            case .skipBackwardTapped:
                let newTime = max(state.playbackTime - 5, 0)
                return .send(.seek(to: newTime))
                
            case .playbackEnded:
                state.resetPlaybackState()
                state.playerState = .stopped
                return .run { _ in audioPlayer.stop() }
                
            case .previousChapter:
                guard state.currentIndex > 0 else { return .none }
                let previousIndex = state.currentIndex - 1
                state.currentIndex = previousIndex
                state.resetPlaybackState()
                return .concatenate(
                    .send(.playbackEnded),
                    .send(.playTapped)
                )
                
            case .nextChapter:
                guard state.currentIndex + 1 < state.chapters.count else { return .none }
                let nextIndex = state.currentIndex + 1
                state.currentIndex = nextIndex
                state.resetPlaybackState()
                return .concatenate(
                    .send(.playbackEnded),
                    .send(.playTapped)
                )
                
            case .observeProgress:
                let duration = state.duration

                return .run { send in
                    for await time in audioPlayer.observeProgress() {
                        await send(.progressUpdated(time))

                        if duration > 0, abs(time - duration) < 0.25 {
                            await send(.playbackEnded)
                            break
                        }
                    }
                }
            }
        }
    }
}

private extension ChapterPlayerFeature.State {
    mutating func resetPlaybackState() {
        isPlaying = false
        playbackTime = 0
        duration = 0
        playbackRate = 1.0
    }
}
