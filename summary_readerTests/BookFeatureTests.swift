//
//  summary_readerTests.swift
//  summary_readerTests
//
//  Created by Serhii Miskiv on 12.04.2025.
//

import Testing
import ComposableArchitecture
@testable import summary_reader

extension BookClient {
    static let successMock = BookClient(
        loadBook: {
            .init(
                id: "book-id",
                title: "Test Title",
                author: "Test Author",
                coverImage: "cover.jpg",
                chapters: []
            )
        }
    )

    static let failureMock = BookClient(
        loadBook: {
            throw BookClientError.fileNotFound
        }
    )
}

struct summary_readerTests {
    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}
