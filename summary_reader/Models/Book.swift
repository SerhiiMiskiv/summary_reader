//
//  Book.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 12.04.2025.
//

import Foundation

struct Book: Decodable, Equatable, Identifiable {
    let id: String
    let title: String
    let author: String
    let coverImage: String
    let chapters: [Chapter]
}

struct Chapter: Decodable, Equatable, Identifiable {
    let id: String
    let title: String
    let text: String
    let audioFile: String
}
