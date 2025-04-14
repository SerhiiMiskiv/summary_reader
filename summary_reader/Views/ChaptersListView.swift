//
//  BookView.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 13.04.2025.
//


import SwiftUI
import ComposableArchitecture

// MARK: - Chapters List View

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
            .navigationTitle("Chapters")
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}

// MARK: - Chapters List

private struct ChaptersList: View {
    let book: AudioBook

    var body: some View {
        List {
            Section(header: Text(book.title).font(.title2)) {
                ForEach(Array(book.chapters.enumerated()), id: \.1.id) { index, chapter in
                    ChapterRowLink(
                        book: book,
                        currentIndex: index,
                    )
                }
            }
        }
    }
}

// MARK: - Chapters Row Link

private struct ChapterRowLink: View {
    let book: AudioBook
    var currentIndex: Int

    var body: some View {
        NavigationLink(
            destination: ChapterPlayerView(
                store: Store(
                    initialState: ChapterPlayerFeature.State(
                        chapters: book.chapters,
                        currentIndex: currentIndex,
                        isPlaying: false,
                    ),
                    reducer: { ChapterPlayerFeature() }
                ),
                coverImage: book.image
            )
        ) {
            VStack(alignment: .leading, spacing: 4) {
                Text(book.chapters[currentIndex].title)
                    .font(.headline)
                Text(book.chapters[currentIndex].text)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .padding(.vertical, 4)
        }
    }
}
