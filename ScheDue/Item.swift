//
//  Item.swift
//  ScheDue
//
//  Created by GATHREAN DELA CRUZ on 2025-10-19.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
