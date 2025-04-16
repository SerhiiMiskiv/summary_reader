//
//  summary_readerTests.swift
//  summary_readerTests
//
//  Created by Serhii Miskiv on 12.04.2025.
//

import Testing
import ComposableArchitecture

@testable import summary_reader

@MainActor
struct LoadAudioBookFeatureTests {

    @Test
    func testSuccessfulAudioBookFetch() async {
        let mockAudioBook = AudioBook(
            id: "1",
            title: "Test Title",
            author: "test Author",
            coverImage: "some_image.jpg",
            chapters: []
        )
        
        let store = TestStore(
            initialState: LoadAudioBookFeature.State(),
            reducer: {
                LoadAudioBookFeature()
            },
            withDependencies: {
                $0.audioBookLoadingClient.loadBook = {
                    mockAudioBook
                }
            }
        )
        
        await store.send(.onAppear) {
            $0.isLoading = true
            $0.error = nil
        }
        
        await store.receive(.bookLoaded(.success(mockAudioBook))) {
            $0.isLoading = false
            $0.error = nil
            $0.book = mockAudioBook
        }
    }
    
    @Test
    func testFailedlAudioBookFetch() async {
        let error: AudioBookLoadingError = .fileNotFound
        
        let store = TestStore(
            initialState: LoadAudioBookFeature.State(),
            reducer: {
                LoadAudioBookFeature()
            },
            withDependencies: {
                $0.audioBookLoadingClient.loadBook = {
                    throw error
                }
            }
        )
        
        await store.send(.onAppear) {
            $0.isLoading = true
            $0.error = nil
        }
        
        await store.receive(.bookLoaded(.failure(error))) {
            $0.isLoading = false
            $0.error = error.localizedDescription
        }
    }
}
