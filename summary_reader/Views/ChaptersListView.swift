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
    @Bindable var store: StoreOf<LoadAudioBookFeature>
    
    var body: some View {
        NavigationView {
            content
        }
        .onAppear {
            store.send(.onAppear)
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading {
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                    .scaleEffect(1.5)
                Text("Loading audiobook...")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        } else if let error = store.error {
            ErrorView(store: store, error: error)
        } else if let book = store.book {
            ChaptersList(book: book)
                .navigationTitle("Chapters")
        } else {
            Text("No data available.")
                .foregroundColor(.gray)
                .padding()
        }
    }
}

// MARK: - Error View

private struct ErrorView: View {
    @Bindable var store: StoreOf<LoadAudioBookFeature>
    let error: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text("Failed to load book")
                .font(.title3)
                .fontWeight(.semibold)
            Text(error)
                .multilineTextAlignment(.center)
                .foregroundColor(.red)
                .padding(.horizontal)
            Button(action: {
                store.send(.onAppear)
            }) {
                Text("Try Again")
                    .bold()
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))    }
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
