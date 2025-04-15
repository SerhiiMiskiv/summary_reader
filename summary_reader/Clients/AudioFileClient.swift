//
//  AudioFileClient.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 15.04.2025.
//

import Foundation
import AVFoundation
import ComposableArchitecture

// MARK: - Error

enum AudioFileClientError: Error {
    case fileNotFound
    case durationNotCalculated(NSError)
}

// MARK: - Client

struct AudioFileClient {
    var getAudioFileURL: (Chapter) async throws -> URL
    var calculateAudioFileDuration: (URL) async throws -> Double
}

// MARK: Dependency Key

extension AudioFileClient: DependencyKey {
    static let liveValue = AudioFileClient(
        getAudioFileURL: { chapter in
            guard let url = Bundle.main.url(
                forResource: chapter.audioFile,
                withExtension: nil) else {
                throw AudioFileClientError.fileNotFound
            }
            
            return url
        },
        calculateAudioFileDuration: { url in
            let asset = AVURLAsset(url: url)
            
            do {
                let cmDuration = try await asset.load(.duration)
                return cmDuration.seconds
            } catch {
                print("Failed to load duration: \(error)")
                throw AudioFileClientError.durationNotCalculated(error as NSError)
            }
        }
    )
}

// MARK: - Dependency Values

extension DependencyValues {
    var audioFileClient: AudioFileClient {
        get { self[AudioFileClient.self] }
        set { self[AudioFileClient.self] = newValue }
    }
}
