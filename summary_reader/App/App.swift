//
//  summary_readerApp.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 12.04.2025.
//

import SwiftUI
import ComposableArchitecture

@main
struct SummaryReaderApp: App {
    var body: some Scene {
        WindowGroup {
            BooksListView(
                store: Store(initialState: BookListFeature.State()) {
                    BookListFeature()
                }
            )
        }
    }
}
