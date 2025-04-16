//
//  BookClient.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 12.04.2025.
//

import Foundation
import ComposableArchitecture

enum AudioBookLoadingError: Error {
    case fileNotFound
}

// MARK: - Client

struct AudioBookLoadingClient {
    var loadBook: @Sendable () async throws -> AudioBook
}

// MARK: - Dependency Key

extension AudioBookLoadingClient: DependencyKey {
    static let liveValue = AudioBookLoadingClient(
        loadBook: {
            // To simulate response time from server
            try await Task.sleep(for: .seconds(1.5))

            guard let url = Bundle.main.url(
                forResource: "the_call_of_cthulhu",
                withExtension: "json") else {
                throw AudioBookLoadingError.fileNotFound
            }

            let data = try Data(contentsOf: url)
            let book = try JSONDecoder().decode(AudioBook.self, from: data)
            return book
        }
    )
}

// MARK: - Dependency Value

extension DependencyValues {
    var audioBookLoadingClient: AudioBookLoadingClient {
        get { self[AudioBookLoadingClient.self] }
        set { self[AudioBookLoadingClient.self] = newValue }
    }
}
