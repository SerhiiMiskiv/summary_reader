//
//  Chapter.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 14.04.2025.
//

import Foundation

struct Chapter: Decodable, Equatable, Identifiable {
    let id: String
    let title: String
    let text: String
    let audioFile: String
}

extension Chapter {
    var audioFileURL: URL {
        guard let url = Bundle.main.url(forResource: audioFile, withExtension: nil) else {
            fatalError("Audio file not found in bundle.")
        }
        
        return url
    }
}
