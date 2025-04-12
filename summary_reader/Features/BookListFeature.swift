//
//  BookListFeature.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 12.04.2025.
//

import Foundation
import ComposableArchitecture

// MARK: - Custom Equtable Error

enum BookClientError: Error, Equatable {
    case failedToLoadDirectory
    case failedToLoadJSON
    case decodingError
    case other(String)
    
    static func from(_ error: Error) -> BookClientError {
        let nsError = error as NSError
        
        if nsError.domain == NSCocoaErrorDomain {
            return .failedToLoadDirectory
        } else if error is DecodingError {
            return .decodingError
        } else {
            return .other(error.localizedDescription)
        }
    }
}

// MARK: - Book List Feature

@Reducer
struct BookListFeature {
    
    struct State: Equatable {
        var books: [AudioBook] = []
        var isLoading = false
        var alert: AlertState<Action>?
    }
    
    enum Action: Equatable {
        case loadBooks
        case booksResponse(Result<[AudioBook], BookClientError>)
        case alertDismissed
    }
    
    @Dependency(\.bookClient) var bookClient
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .loadBooks:
            state.isLoading = true
            return .run { send in
                await send(
                    .booksResponse(
                        Result {
                            try await bookClient.loadBooks()
                        }.mapError { BookClientError.from($0) }
                    )
                )
            }

        case let .booksResponse(.success(books)):
            state.books = books
            print("Book Response success: \(books)")
            state.isLoading = false
            return .none

        case let .booksResponse(.failure(error)):
            print("Book Response error: \(error)")
            state.isLoading = false
            state.alert = AlertState {
                TextState("Failed to load books")
            } actions: {
                ButtonState(action: .alertDismissed) {
                    TextState("OK")
                }
            }
            return .none

        case .alertDismissed:
            state.alert = nil
            return .none
        }
    }
}
