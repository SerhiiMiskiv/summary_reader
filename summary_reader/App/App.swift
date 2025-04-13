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
            BookView(
                store: Store(
                    initialState: BookFeature.State(),
                    reducer: { BookFeature() }
                )
            )
        }
    }
}
