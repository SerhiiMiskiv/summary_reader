import SwiftUI
import ComposableArchitecture

struct BookView: View {
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
