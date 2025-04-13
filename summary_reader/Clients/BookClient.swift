//
//  BookClient.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 12.04.2025.
//

import Foundation
import ComposableArchitecture

enum BookClientError: Error {
    case fileNotFound
}

struct BookClient {
    var loadBook: @Sendable () async throws -> Book
}

extension BookClient: DependencyKey {
    static let liveValue = BookClient(
        loadBook: {
            guard let url = Bundle.main.url(
                forResource: "the_call_of_cthulhu",
                withExtension: "json") else {
                throw BookClientError.fileNotFound
            }

            let data = try Data(contentsOf: url)
            let book = try JSONDecoder().decode(Book.self, from: data)
            return book
        }
    )
}

extension DependencyValues {
    var bookClient: BookClient {
        get { self[BookClient.self] }
        set { self[BookClient.self] = newValue }
    }
}
