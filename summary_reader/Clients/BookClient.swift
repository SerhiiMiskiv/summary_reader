//
//  BookClient.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 12.04.2025.
//

import Foundation
import ComposableArchitecture

struct BookClient {
    var loadBooks: @Sendable () async throws -> [AudioBook]
}

extension DependencyValues {
    var bookClient: BookClient {
        get { self[BookClientKey.self] }
        set { self[BookClientKey.self] = newValue }
    }
}

private enum BookClientKey: DependencyKey {
    static let liveValue = BookClient(
        loadBooks: {
            let fileManager = FileManager.default
            guard let resourcesFolder = Bundle.main.resourceURL?.appendingPathComponent("books") else {
                    fatalError("Books folder not found!")
            }
            
            let subdirectories = try fileManager.contentsOfDirectory(
                at: resourcesFolder,
                includingPropertiesForKeys: nil
            ).filter { $0.hasDirectoryPath }
            
            var audioBooks: [AudioBook] = []
            
            for directory in subdirectories {
                let jsonFiles = try fileManager.contentsOfDirectory(
                    at: directory,
                    includingPropertiesForKeys: nil
                )
                .filter { $0.pathExtension == "json" }

                guard let jsonURL = jsonFiles.first else {
                    print("Json not found! Pay attention")
                    continue
                }

                let data = try Data(contentsOf: jsonURL)
                let book = try JSONDecoder().decode(AudioBook.self, from: data)
                
                audioBooks.append(book)
            }
            
            return audioBooks
        }
    )
}
