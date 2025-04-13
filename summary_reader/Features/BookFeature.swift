//
//  BookListFeature.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 12.04.2025.
//

import Foundation
import ComposableArchitecture

@Reducer
struct BookFeature {
    @ObservableState
    struct State: Equatable {
        var book: Book?
        var isLoading: Bool = false
        var error: String?
    }

    enum Action: Equatable, BindableAction {
        case onAppear
        case bookLoaded(Result<Book, BookClientError>)
        case binding(BindingAction<State>)
    }

    @Dependency(\.bookClient) var bookClient

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.error = nil
                return .run { send in
                    await send(.bookLoaded(
                        Result {
                            try await bookClient.loadBook()
                        }
                        .mapError { $0 as? BookClientError ?? .fileNotFound }
                    ))
                }

            case let .bookLoaded(.success(book)):
                state.book = book
                state.isLoading = false
                return .none

            case let .bookLoaded(.failure(error)):
                state.error = error.localizedDescription
                state.isLoading = false
                return .none

            case .binding:
                return .none
            }
        }
    }
}
