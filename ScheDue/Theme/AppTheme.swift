//
//  AppTheme.swift
//  Nota
//
//  Created by GATHREAN DELA CRUZ on 2025-10-24.
//

import SwiftUI

struct AppTheme {
    // Colors
    static let background = Color(hex: "e7e7e7")
    static let cardBackground = Color(.secondarySystemBackground)
    static let accentBlue = Color.blue
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    
    // Header font helper
    static func headerFont(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        return .custom("InstrumentSerif-Regular", size: size)
    }
    
    // Spacing
    static let paddingHorizontal: CGFloat = 20
    static let paddingVertical: CGFloat = 12
    
    // Calendar
    static let dayCellHeight: CGFloat = 80
}
