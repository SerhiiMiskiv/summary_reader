//
//  BookListFeature.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 12.04.2025.
//

import Foundation
import ComposableArchitecture

@Reducer
struct LoadAudioBookFeature {
    
    @ObservableState
    struct State: Equatable {
        var book: AudioBook?
        var isLoading: Bool = false
        var error: String?
    }

    enum Action: Equatable, BindableAction {
        case onAppear
        case bookLoaded(Result<AudioBook, BookClientError>)
        case binding(BindingAction<State>)
    }

    @Dependency(\.bookClient) var bookClient

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none
                
            case .onAppear:
                state.isLoading = true
                state.error = nil
                return .run { send in
                    do {
                        let book = try await bookClient.loadBook()
                        await send(.bookLoaded(.success(book)))
                    } catch {
                        await send(.bookLoaded(.failure(error as! BookClientError)))
                    }
                }
                
            case let .bookLoaded(.success(book)):
                state.book = book
                state.isLoading = false
                return .none
                
            case let .bookLoaded(.failure(error)):
                state.error = error.localizedDescription
                state.isLoading = false
                return .none
            }
        }
    }
}
