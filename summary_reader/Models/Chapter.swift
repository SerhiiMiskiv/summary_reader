//
//  Chapter.swift
//  summary_reader
//
//  Created by Serhii Miskiv on 12.04.2025.
//

import Foundation

struct Chapter: Equatable, Codable, Identifiable {
    let id: String
    let title: String
    let text: String
    let audioFile: String
}
