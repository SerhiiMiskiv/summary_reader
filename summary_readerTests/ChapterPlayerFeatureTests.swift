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
    func testStartPlayingObserveProgressAndEnds() async {
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
            seek: { _ in },
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
        
        await store.receive(.playNextIfExist)
        await store.receive(.stop) {
            $0.isPlaying = false
            $0.playbackTime = 0
            $0.duration = 0
            $0.playbackRate = 1.0
            $0.playerState = .stopped
        }
    }
    
    
    @Test
    func testSetPlaybackRate() async {
        let mockChapter = Chapter(
            id: "3",
            title: "Rate Test",
            text: "Testing playback rate",
            audioFile: "chapter_rate.mp3"
        )

        let mockChapters = [mockChapter]
        let mockAudioPlayer = AudioPlayerClient(
            play: { _ in },
            playWithoutReplacing: {},
            pause: {},
            stop: {},
            seek: { _ in },
            setRate: { _ in
            },
            observeProgress: {
                AsyncStream { _ in }
            }
        )

        let mockAudioFileClient = AudioFileClient(
            getAudioFileURL: { _ in URL(string: "https://example.com/audio.mp3")! },
            calculateAudioFileDuration: { _ in 0 }
        )

        let store = TestStore(
            initialState: ChapterPlayerFeature.State(chapters: mockChapters),
            reducer: { ChapterPlayerFeature() },
            withDependencies: {
                $0.audioPlayer = mockAudioPlayer
                $0.audioFileClient = mockAudioFileClient
            }
        )

        await store.send(.setRate(2.0)) {
            $0.playbackRate = 2.0
        }
        
        await store.send(.setRate(1.0)) {
            $0.playbackRate = 1.0
        }
        
        await store.send(.setRate(0.5)) {
            $0.playbackRate = 0.5
        }
        
        await store.send(.setRate(1.5)) {
            $0.playbackRate = 1.5
        }
    }
    
    @Test
    func testSkipForwardAndBackward() async {
        let mockChapter = Chapter(
            id: "3",
            title: "Rate Test",
            text: "Testing playback rate",
            audioFile: "chapter_rate.mp3"
        )

        let mockChapters = [mockChapter]
        let mockAudioPlayer = AudioPlayerClient(
            play: { _ in },
            playWithoutReplacing: {},
            pause: {},
            stop: {},
            seek: { _ in },
            setRate: { _ in
            },
            observeProgress: {
                AsyncStream { _ in }
            }
        )

        let mockAudioFileClient = AudioFileClient(
            getAudioFileURL: { _ in URL(string: "https://example.com/audio.mp3")! },
            calculateAudioFileDuration: { _ in 0 }
        )

        let store = TestStore(
            initialState: ChapterPlayerFeature.State(
                chapters: mockChapters,
                duration: 100.0
            ),
            reducer: { ChapterPlayerFeature() },
            withDependencies: {
                $0.audioPlayer = mockAudioPlayer
                $0.audioFileClient = mockAudioFileClient
            }
        )
            
        await store.send(.seek(to: 50.0)) {
            $0.playbackTime = 50.0
        }
        
        await store.send(.skipForward)
        await store.receive(.seek(to: 60.0)) {
            $0.playbackTime = 60.0
        }
        
        await store.send(.skipBackward)
        await store.receive(.seek(to: 55.0)) {
            $0.playbackTime = 55.0
        }

        await store.send(.seek(to: 3.0)) {
            $0.playbackTime = 3.0
        }
        await store.send(.skipBackward)
        await store.receive(.seek(to: 0)) {
            $0.playbackTime = 0
        }

        await store.send(.seek(to: 95.0)) {
            $0.playbackTime = 95
        }
        await store.send(.skipForward)
        await store.receive(.seek(to: 100)) {
            $0.playbackTime = 100
        }
    }
    
    @Test
    func testNextChapter() async {
        let mockChapter1 = Chapter(
            id: "1",
            title: "Test title 1",
            text: "Test text 1",
            audioFile: "test_file_1.mp3"
        )
        let mockChapter2 = Chapter(
            id: "2",
            title: "Test title 2",
            text: "Test text 2",
            audioFile: "test_file_2.mp3"
        )
        
        let mockChapters: [Chapter] = [mockChapter1, mockChapter2]
        
        let mockDuration: TimeInterval = 15.0
        let mockProgress: [TimeInterval] = [mockDuration]
        
        let mockedPlayer = AudioPlayerClient(
            play: { _ in },
            playWithoutReplacing: { },
            pause: { },
            stop: { },
            seek: { _ in },
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
                URL(string: "https://example.com/some_audio.mp3")!
            },
            calculateAudioFileDuration: { _ in
                mockDuration
            }
        )
        
        
        let store = TestStore(
            initialState: ChapterPlayerFeature.State(
                chapters: mockChapters,
                currentIndex: 0
            ),
            reducer: {
                ChapterPlayerFeature()
            },
            withDependencies: {
                $0.audioPlayer = mockedPlayer
                $0.audioFileClient = mockAudioFileClient
            }
        )
        
        // Switching next chapter once
        await store.send(.nextChapter) {
            $0.currentIndex = $0.currentIndex + 1
            $0.isPlaying = false
            $0.playbackTime = 0
            $0.duration = 0
            $0.playbackRate = 1.0
        }
        await store.receive(.stop) {
            $0.isPlaying = false
            $0.playbackTime = 0
            $0.duration = 0
            $0.playbackRate = 1.0
            $0.playerState = .stopped
        }
        await store.receive(.play)
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
        await store.receive(.playNextIfExist)
        await store.receive(.stop) {
            $0.isPlaying = false
            $0.playbackTime = 0
            $0.duration = 0
            $0.playbackRate = 1.0
            $0.playerState = .stopped
        }
        
        // Switching next chapter twice and
        // checking if we're not out of bounds
        await store.send(.nextChapter)
    }
    
    @Test
    func testPreviousChapter() async {
        let mockChapter1 = Chapter(
            id: "1",
            title: "Test title 1",
            text: "Test text 1",
            audioFile: "test_file_1.mp3"
        )
        let mockChapter2 = Chapter(
            id: "2",
            title: "Test title 2",
            text: "Test text 2",
            audioFile: "test_file_2.mp3"
        )
        
        let mockChapters: [Chapter] = [mockChapter1, mockChapter2]
        let mockDuration: TimeInterval = 15.0
        
        let mockedPlayer = AudioPlayerClient(
            play: { _ in },
            playWithoutReplacing: { },
            pause: { },
            stop: { },
            seek: { _ in },
            setRate: { _ in },
            observeProgress: {
                AsyncStream { _ in }
            }
        )
        
        let mockAudioFileClient = AudioFileClient(
            getAudioFileURL: { _ in
                URL(string: "https://example.com/some_audio.mp3")!
            },
            calculateAudioFileDuration: { _ in
                mockDuration
            }
        )
        
        
        let store = TestStore(
            initialState: ChapterPlayerFeature.State(
                chapters: mockChapters,
                currentIndex: 1
            ),
            reducer: {
                ChapterPlayerFeature()
            },
            withDependencies: {
                $0.audioPlayer = mockedPlayer
                $0.audioFileClient = mockAudioFileClient
            }
        )
        store.exhaustivity = .off
        
        // Switching previous chapter once
        await store.send(.previousChapter) {
            $0.currentIndex = 0
            $0.isPlaying = false
            $0.playbackTime = 0
            $0.duration = 0
            $0.playbackRate = 1.0
        }
        
        await store.receive(.stop) {
            $0.isPlaying = false
            $0.playbackTime = 0
            $0.duration = 0
            $0.playbackRate = 1.0
            $0.playerState = .stopped
        }
        await store.receive(.play)
        await store.receive(.calculateDuration)
        await store.receive(.durationLoaded(mockDuration)) {
            $0.duration = mockDuration
        }
        await store.receive(.startPlaying) {
            $0.isPlaying = true
        }
        await store.receive(.observeProgress)
        
        // Switching previous chapter twice and
        // checking if we're not out of bounds
        await store.send(.previousChapter)
    }
    
    @Test
    func testFileUrlError() async {
        let mockChapter = Chapter(
            id: "1",
            title: "Test title 1",
            text: "Test text 1",
            audioFile: "test_file_1.mp3"
        )
        
        let mockChapters: [Chapter] = [mockChapter]
        let mockError = AudioFileClientError.fileNotFound(
            chapterID: mockChapter.id,
            fileName: mockChapter.audioFile
        )
        
        let mockedPlayer = AudioPlayerClient(
            play: { _ in },
            playWithoutReplacing: { },
            pause: { },
            stop: { },
            seek: { _ in },
            setRate: { _ in },
            observeProgress: {
                AsyncStream { _ in
                }
            }
        )
        
        let mockAudioFileClient = AudioFileClient(
            getAudioFileURL: { _ in
                throw mockError
            },
            calculateAudioFileDuration: { _ in
                throw NSError()
            }
        )
        
        let store = TestStore(
            initialState: ChapterPlayerFeature.State(
                chapters: mockChapters,
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
        await store.receive(.error(reason: mockError.localizedDescription)) {
            $0.error = mockError.localizedDescription
        }
    }
    
    @Test
    func testFileDurationCalculationError() async {
        let mockChapter = Chapter(
            id: "1",
            title: "Test title 1",
            text: "Test text 1",
            audioFile: "test_file_1.mp3"
        )
        
        let mockChapters: [Chapter] = [mockChapter]
        let mockError = AudioFileClientError.durationNotCalculated(
            file: mockChapter.audioFile,
            underlying: NSError(
                domain: "com.test.audio",
                code: 1001,
                userInfo: [
                    NSLocalizedDescriptionKey: "Mock duration loading failed"
                ]
            )
        )
        
        let mockedPlayer = AudioPlayerClient(
            play: { _ in },
            playWithoutReplacing: { },
            pause: { },
            stop: { },
            seek: { _ in },
            setRate: { _ in },
            observeProgress: {
                AsyncStream { _ in
                }
            }
        )
        
        let mockAudioFileClient = AudioFileClient(
            getAudioFileURL: { _ in
                URL(string: "https://example.com/\(mockChapter.audioFile)")!
            },
            calculateAudioFileDuration: { _ in
                throw mockError
            }
        )
        
        let store = TestStore(
            initialState: ChapterPlayerFeature.State(
                chapters: mockChapters,
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
        await store.receive(.error(reason: mockError.localizedDescription)) {
            $0.error = mockError.localizedDescription
        }
    }
}
