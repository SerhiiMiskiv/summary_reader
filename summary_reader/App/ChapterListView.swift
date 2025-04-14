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
                    ChaptersList(book: book)

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

private struct ChaptersList: View {
    let book: Book

    var body: some View {
        List {
            Section(header: Text(book.title).font(.title2)) {
                ForEach(Array(book.chapters.enumerated()), id: \.1.id) { index, chapter in
                    ChapterRowLink(
                        chapters: book.chapters,
                        currentIndex: index,
                    )
                }
            }
        }
    }
}


private struct ChapterRowLink: View {
    let chapters: [Chapter]
    var currentIndex: Int

    var body: some View {
        NavigationLink(
            destination: ChapterPlayerView(
                store: Store(
                    initialState: ChapterPlayerFeature.State(
                        chapters: chapters,
                        currentIndex: currentIndex,
                        isPlaying: false,
                    ),
                    reducer: { ChapterPlayerFeature() }
                ),
            )
        ) {
            VStack(alignment: .leading, spacing: 4) {
                Text(chapters[currentIndex].title)
                    .font(.headline)
                Text(chapters[currentIndex].text)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(.vertical, 4)
        }
    }
}
