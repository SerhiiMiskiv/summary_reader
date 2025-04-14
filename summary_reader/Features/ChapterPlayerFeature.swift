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
        case play
        case startPlaying
        
        case observeProgress
        case progressUpdated(TimeInterval)

        case pause
        case stop

        case calculateDuration
        case durationLoaded(TimeInterval)

        case skipForward
        case skipBackward
        case seek(to: TimeInterval)
        
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
                
            case .play:
                return .concatenate(
                    .send(.calculateDuration),
                    .send(.startPlaying),
                    .send(.observeProgress)
                )
                
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
                
            case .observeProgress:
                let duration = state.duration
                return .run { send in
                    for await time in audioPlayer.observeProgress() {
                        await send(.progressUpdated(time))

                        if duration > 0, abs(time - duration) < 0.25 {
                            await send(.stop)
                            break
                        }
                    }
                }
                
            case let .progressUpdated(time):
                state.playbackTime = time
                return .none
                
            case .pause:
                state.isPlaying = false
                state.playerState = .paused
                return .run { _ in audioPlayer.pause() }
                
            case .stop:
                state.resetPlaybackState()
                state.playerState = .stopped
                return .run { _ in audioPlayer.stop() }
                
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
                
            case let .durationLoaded(duration):
                state.duration = duration
                return .none
                
            case let .setRate(rate):
                state.playbackRate = rate
                return .run { _ in audioPlayer.setRate(rate) }
                
            case .skipForward:
                let newTime = min(state.playbackTime + 10, state.duration)
                print("New time \(newTime)")
                return .send(.seek(to: newTime))
                
            case .skipBackward:
                let newTime = max(state.playbackTime - 5, 0)
                return .send(.seek(to: newTime))
                
            case let .seek(to: position):
                state.playbackTime = position
                let rate = state.playbackRate
                return .run { _ in audioPlayer.seek(position, rate) }
                
            case .previousChapter:
                guard state.currentIndex > 0 else { return .none }
                let previousIndex = state.currentIndex - 1
                state.currentIndex = previousIndex
                state.resetPlaybackState()
                return .concatenate(
                    .send(.stop),
                    .send(.play)
                )
                
            case .nextChapter:
                guard state.currentIndex + 1 < state.chapters.count else { return .none }
                let nextIndex = state.currentIndex + 1
                state.currentIndex = nextIndex
                state.resetPlaybackState()
                return .concatenate(
                    .send(.stop),
                    .send(.play)
                )
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
