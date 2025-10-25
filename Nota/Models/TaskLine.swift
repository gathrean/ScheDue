//
//  TaskLine.swift
//  Nota
//
//  Created by GATHREAN DELA CRUZ on 2025-10-24.
//

import Foundation

struct TaskLine: Identifiable {
    let id = UUID()
    var text: String
    var status: TaskStatus = .editing
    var parsedData: ParsedInput?

    // Computed properties for easy access
    var hasScheduledTime: Bool {
        parsedData?.time != nil
    }

    var hasLocation: Bool {
        parsedData?.location != nil
    }

    var isEvent: Bool {
        parsedData?.intent == .event
    }
}
