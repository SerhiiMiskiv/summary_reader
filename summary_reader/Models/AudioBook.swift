//
//  Book.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 12.04.2025.
//

import Foundation
import UIKit

// MARK: - Image Loading Error

enum AudioBookError: LocalizedError, Equatable {
    case imageNotExist(String)
    
    var localizedDescription: String {
        switch self {
        case .imageNotExist(let name):
            return "Image \(name) not exist"
        }
    }
}

// MARK: - AudioBook

struct AudioBook: Decodable, Equatable, Identifiable {
    let id: String
    let title: String
    let author: String
    let coverImage: String
    let chapters: [Chapter]
}

extension AudioBook {
    func loadCoverImage() async throws -> UIImage {
        // To simulate response time from server
        try await Task.sleep(for: .seconds(1.5))
        
        guard
            let url = Bundle.main.url(
                forResource: coverImage,
                withExtension: nil
            ),
            let data = try? Data(contentsOf: url),
            let uiImage = UIImage(data: data)
        else {
            throw AudioBookError.imageNotExist(coverImage)
        }
        
        return uiImage
    }
}
