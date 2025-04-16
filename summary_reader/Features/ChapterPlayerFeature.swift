//
//  ChapterFeature.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 13.04.2025.
//

import Foundation
import AVFoundation
import ComposableArchitecture

// MARK: - Reducer

@Reducer
struct ChapterPlayerFeature {
    
    enum PlayerState: Equatable {
        case newlyAdded
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
        var error: String?
    }
    
    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case play
        case startPlaying
        case playNextIfExist
        
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
        
        case error(reason: String)
    }
    
    @Dependency(\.audioPlayer) var audioPlayer
    @Dependency(\.audioFileClient) var audioFileClient
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .play:
                return .send(.calculateDuration)
                
            case .startPlaying:
                state.isPlaying = true
                
                let chapter = state.currentChapter
                let playerState = state.playerState
                
                let shouldReplaceItem = playerState == .newlyAdded || playerState == .stopped
                
                return .run { send in
                    if shouldReplaceItem {
                        do {
                            let url = try await audioFileClient.getAudioFileURL(chapter)
                            try await audioPlayer.play(url)
                        }
                        catch {
                            await send(.error(reason: error.localizedDescription))
                        }
                    }
                    else {
                        audioPlayer.playWithoutReplacing()
                    }
                    
                    await send(.observeProgress)
                }
                
            case .playNextIfExist:
                guard state.currentIndex + 1 < state.chapters.count else {
                    return .send(.stop)
                }
                
                return .send(.nextChapter)
                
            case .observeProgress:
                let duration = state.duration
                return .run { send in
                    for await time in audioPlayer.observeProgress() {
                        await send(.progressUpdated(time))
                        if duration > 0, abs(time - duration) < 0.25 {
                            await send(.playNextIfExist)
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
                    do {
                        let url = try await audioFileClient.getAudioFileURL(chapter)
                        let duration = try await audioFileClient.calculateAudioFileDuration(url)
                        await send(.durationLoaded(duration))
                    }
                    catch {
                        await send(.error(reason: error.localizedDescription))
                    }
                }
                
            case let .durationLoaded(newDuration):
                state.duration = newDuration
                return .send(.startPlaying)
                
            case let .setRate(rate):
                state.playbackRate = rate
                let isPaused = state.isPlaying == false
                return .run { _ in audioPlayer.setRate(rate, isPaused) }
                
            case .skipForward:
                let newTime = min(state.playbackTime + 10, state.duration)
                return .send(.seek(to: newTime))
                
            case .skipBackward:
                let newTime = max(state.playbackTime - 5, 0)
                return .send(.seek(to: newTime))
                
            case let .seek(to: position):
                state.playbackTime = position
                return .run { _ in audioPlayer.seek(position) }
                
            case .previousChapter:
                guard state.currentIndex > 0 else {
                    return .none
                }
                let previousIndex = state.currentIndex - 1
                state.currentIndex = previousIndex
                state.resetPlaybackState()
                return .concatenate(
                    .send(.stop),
                    .send(.play)
                )
                
            case .nextChapter:
                guard state.currentIndex + 1 < state.chapters.count else {
                    return .none
                }
                
                let nextIndex = state.currentIndex + 1
                state.currentIndex = nextIndex
                state.resetPlaybackState()
                return .concatenate(
                    .send(.stop),
                    .send(.play)
                )
                
            case let .error(error):
                state.error = error
                return .none
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
