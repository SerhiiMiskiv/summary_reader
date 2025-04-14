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
    @ObservableState
    struct State: Equatable {
        var chapter: Chapter
        var isPlaying: Bool = false
        var playbackTime: TimeInterval = 0
        var duration: TimeInterval = 0
        var playbackRate: Double = 1.0
        var chapterIndex: Int = 0
        var totalChapters: Int = 0
    }
    
    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case playTapped
        case pauseTapped
        case stopTapped
        case skipForwardTapped
        case skipBackwardTapped
        case seek(to: TimeInterval)
        case progressUpdated(TimeInterval)
        case durationLoaded(TimeInterval)
        case setRate(Double)
        case playbackEnded
    }
    
    @Dependency(\.audioPlayer) var audioPlayer
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .playTapped:
                state.isPlaying = true
                
                return .run { [chapter = state.chapter, rate = state.playbackRate] send in
                    var resolvedDuration: TimeInterval = 0

                    if !audioPlayer.isItemLoaded() {
                        if let url = Bundle.main.url(forResource: chapter.audioFile, withExtension: nil) {
                            let asset = AVURLAsset(url: url)
                            
                            do {
                                let cmDuration = try await asset.load(.duration)
                                resolvedDuration = cmDuration.seconds
                                await send(.durationLoaded(cmDuration.seconds))
                            } catch {
                                print("Failed to load duration: \(error)")
                            }
                            
                            do {
                                try await audioPlayer.play(url)
                            } catch {
                                print("Failed to play audio:", error)
                                return
                            }
                        } else {
                            print("Audio file not found in bundle.")
                            return
                        }
                    } else {
                        audioPlayer.playWithoutReplacing()
                    }
                    
                    audioPlayer.setRate(rate)
                    
                    for await time in audioPlayer.observeProgress() {
                        await send(.progressUpdated(time))
                        
                        if resolvedDuration > 0, abs(time - resolvedDuration) < 0.25 {
                            await send(.playbackEnded)
                            break
                        }
                    }
                }
                
            case .pauseTapped:
                state.isPlaying = false
                return .run { _ in
                    audioPlayer.pause()
                }
                
            case .stopTapped:
                state.isPlaying = false
                return .run { _ in
                    audioPlayer.stop()
                }
                
            case let .progressUpdated(time):
                state.playbackTime = time
                return .none
                
            case let .durationLoaded(duration):
                state.duration = duration
                return .none
                
            case let .setRate(rate):
                state.playbackRate = rate
                return .run { _ in
                    audioPlayer.setRate(rate)
                }
                
            case let .seek(to: position):
                state.playbackTime = position
                let rate = state.playbackRate
                return .run { _ in
                    @Dependency(\.audioPlayer) var audioPlayer
                    audioPlayer.seek(position, rate)
                }
                
            case .skipForwardTapped:
                let newTime = min(state.playbackTime + 10, state.duration)
                return .send(.seek(to: newTime))
                
            case .skipBackwardTapped:
                let newTime = max(state.playbackTime - 5, 0)
                return .send(.seek(to: newTime))
                
            case .playbackEnded:
                state.isPlaying = false
                state.playbackTime = 0
                state.playbackRate = 1.0
            
                return .run { _ in
                    @Dependency(\.audioPlayer) var audioPlayer
                    audioPlayer.stop()
                }
            }
        }
    }
}
