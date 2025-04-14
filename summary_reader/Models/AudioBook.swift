//
//  Book.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 12.04.2025.
//

import Foundation
import UIKit

struct AudioBook: Decodable, Equatable, Identifiable {
    let id: String
    let title: String
    let author: String
    let coverImage: String
    let chapters: [Chapter]
}

extension AudioBook {
    var image: UIImage {
        guard
            let url = Bundle.main.url(
                forResource: coverImage,
                withExtension: nil
            ),
            let data = try? Data(contentsOf: url),
            let uiImage = UIImage(data: data)
        else {
            fatalError("No cover image found")
        }
        
        return uiImage
    }
}
