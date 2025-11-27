//
//  ParsedInput.swift
//  Nota
//
//  Created by GATHREAN DELA CRUZ on 2025-10-24.
//

import Foundation

struct ParsedInput {
    let originalText: String
    let intent: Intent
    let date: Date?
    let time: String?
    let location: String?
    let title: String
    let confidence: Double // 0.0 to 1.0

    enum Intent {
        case event
        case task
        case note
        case unknown
    }

    init(originalText: String, intent: Intent = .unknown, date: Date? = nil, time: String? = nil, location: String? = nil, title: String? = nil, confidence: Double = 0.0) {
        self.originalText = originalText
        self.intent = intent
        self.date = date
        self.time = time
        self.location = location
        self.title = title ?? originalText
        self.confidence = confidence
    }
}
