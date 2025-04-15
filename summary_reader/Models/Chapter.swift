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
