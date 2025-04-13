//
//  ChapterDetailView.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 13.04.2025.
//

import SwiftUI
import ComposableArchitecture

struct ChapterDetailView: View {
    let store: StoreOf<ChapterPlayerFeature>

    var body: some View {
        ChapterPlayerView(store: store)
    }
}
