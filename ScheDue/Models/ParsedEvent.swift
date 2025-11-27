//
//  ParsedEvent.swift
//  Nota
//
//  Created by GATHREAN DELA CRUZ on 2025-10-24.
//

import Foundation

struct ParsedEvent {
    let title: String
    let date: Date
    let type: EventType
    let time: String?
    
    enum EventType {
        case event
        case task
    }
}
