//
//  BookView.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 13.04.2025.
//


import SwiftUI
import ComposableArchitecture

struct ChaptersListView: View {
    @Bindable var store: StoreOf<BookFeature>

    var body: some View {
        NavigationView {
            Group {
                if store.isLoading {
                    ProgressView("Loading...")
                } else if let error = store.error {
                    VStack(spacing: 16) {
                        Text("Failed to load book:")
                            .font(.headline)
                        Text(error)
                            .foregroundColor(.red)
                        Button("Retry") {
                            store.send(.onAppear)
                        }
                    }
                } else if let book = store.book {
                    List {
                        Section(header: Text(book.title).font(.title2)) {
                            ForEach(book.chapters) { chapter in
                                ChapterRowLink(chapter: chapter)
                            }
                        }
                    }
                } else {
                    Text("No data available.")
                }
            }
            .navigationTitle("Book")
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}


struct ChapterRowLink: View {
    let chapter: Chapter

    var body: some View {
        NavigationLink(
            destination: ChapterPlayerView(
                store: Store(
                    initialState: ChapterPlayerFeature.State(
                        chapter: chapter,
                        isPlaying: false,
                    ),
                    reducer: { ChapterPlayerFeature() }
                )
            )
        ) {
            VStack(alignment: .leading, spacing: 4) {
                Text(chapter.title)
                    .font(.headline)
                Text(chapter.text)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(.vertical, 4)
        }
    }
}
