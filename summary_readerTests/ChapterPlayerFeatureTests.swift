//
//  ChapterPlayerFeatureTests.swift
//  summary_readerTests
//
//  Created by Serhii Miskiv on 15.04.2025.
//

import Foundation
import Testing
import AVFoundation
import ComposableArchitecture

@testable import summary_reader

@MainActor
struct ChapterPlayerFeatureTests {
    
    @Test
    func testStartPlayingAndObserveProgress() async {
        let mockChapter = Chapter(
            id: "1",
            title: "Test title", 
            text: "Test text",
            audioFile: "test_file.mp3"
        )
        
        let mockChapters: [Chapter] = [mockChapter]
        let mockDuration: TimeInterval = 15.0
        let mockProgress: [TimeInterval] = [1, 2, 5, 7, 10, 15.0]
        
        let mockedPlayer = AudioPlayerClient(
            play: { _ in },
            playWithoutReplacing: { },
            pause: { },
            stop: { },
            seek: { _, _ in },
            setRate: { _ in },
            observeProgress: {
                AsyncStream { continuation in
                    for time in mockProgress {
                        continuation.yield(time)
                    }
                }
            }
        )
        
        let mockAudioFileClient = AudioFileClient(
            getAudioFileURL: { _ in
                URL(string: "https://example.com/\(mockChapter.audioFile)")!
            },
            calculateAudioFileDuration: { _ in
                mockDuration
            }
        )
        
        
        let store = TestStore(
            initialState: ChapterPlayerFeature.State(
                chapters: mockChapters
            ),
            reducer: {
                ChapterPlayerFeature()
            },
            withDependencies: {
                $0.audioPlayer = mockedPlayer
                $0.audioFileClient = mockAudioFileClient
            }
        )
        
        await store.send(.play)
        
        await store.receive(.calculateDuration)
        await store.receive(.durationLoaded(mockDuration)) {
            $0.duration = mockDuration
        }
        
        await store.receive(.startPlaying) {
            $0.isPlaying = true
        }
        
        await store.receive(.observeProgress)
        for time in mockProgress {
            await store.receive(.progressUpdated(time)) {
                $0.playbackTime = time
            }
        }
        
        await store.receive(.stop) {
            $0.isPlaying = false
            $0.playbackTime = 0
            $0.duration = 0
            $0.playbackRate = 1.0
            $0.playerState = .stopped
        }
    }
}
