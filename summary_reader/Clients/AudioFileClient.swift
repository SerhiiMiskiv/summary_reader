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

enum AudioFileClientError: LocalizedError, Equatable {
    case fileNotFound(chapterID: String, fileName: String)
    case durationNotCalculated(file: String, underlying: NSError)

    var errorDescription: String? {
        switch self {
        case let .fileNotFound(chapterID, fileName):
            return "Audio file '\(fileName)' for chapter '\(chapterID)' was not found in the app bundle."
            
        case let .durationNotCalculated(file, underlying):
            return "Failed to calculate duration for '\(file)'. Underlying error: \(underlying.localizedDescription)"
        }
    }
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
                throw AudioFileClientError.fileNotFound(
                    chapterID: chapter.id,
                    fileName: chapter.audioFile
                )
            }
            
            return url
        },
        calculateAudioFileDuration: { url in
            let asset = AVURLAsset(url: url)
            
            do {
                let cmDuration = try await asset.load(.duration)
                return cmDuration.seconds
            } catch {
                throw AudioFileClientError.durationNotCalculated(
                    file: url.lastPathComponent,
                    underlying: error as NSError
                )
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
