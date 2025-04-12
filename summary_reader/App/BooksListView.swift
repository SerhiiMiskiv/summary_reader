import SwiftUI
import ComposableArchitecture

struct BooksListView: View {
    let store: StoreOf<BookListFeature>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            NavigationStack {
                Group {
                    if viewStore.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewStore.books.isEmpty {
                        Text("No books found")
                            .foregroundStyle(.secondary)
                    } else {
                        List(viewStore.books) { book in
                            HStack(spacing: 16) {
                                Image(uiImage: loadImage(named: book.coverImage))
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 90)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                VStack(alignment: .leading) {
                                    Text(book.title)
                                        .font(.headline)
                                    Text(book.author)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listStyle(.plain)
                    }
                }
                .navigationTitle("Summaries")
//                           .alert(
//                               store: store.scope(state: \.alert, action: { $0 })
//                           )
                           .task {
                               await viewStore.send(.loadBooks).finish()
                           }
            }
        }
    }

    private func loadImage(named name: String) -> UIImage {
        guard let url = Bundle.main.url(forResource: name, withExtension: nil),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return UIImage(systemName: "book")!
        }
        return image
    }}
