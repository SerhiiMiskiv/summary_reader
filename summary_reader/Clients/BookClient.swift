//
//  BookClient.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 12.04.2025.
//

import Foundation
import ComposableArchitecture

struct BookClient {
    var loadBooks: @Sendable () async throws -> [AudioBook]
}

extension DependencyValues {
    var bookClient: BookClient {
        get { self[BookClientKey.self] }
        set { self[BookClientKey.self] = newValue }
    }
}

private enum BookClientKey: DependencyKey {
    static let liveValue = BookClient(
        loadBooks: {
            guard let jsonURL = Bundle.main.url(forResource: "the_call_of_cthulhu", withExtension: "json") else {
                fatalError("❌ JSON not found in bundle.")
            }

            let data = try Data(contentsOf: jsonURL)
            let book = try JSONDecoder().decode(AudioBook.self, from: data)

            print("✅ Loaded book:", book.title)
            return [book]
        }
    )
}
