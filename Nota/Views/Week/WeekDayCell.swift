//
//  WeekDayCell.swift
//  Nota
//
//  Created by GATHREAN DELA CRUZ on 2025-10-24.
//

import SwiftUI

struct WeekDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void
    
    private var dayLetter: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(1))
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayLetter)
                .appFont(size: 12, weight: .medium)
                .foregroundColor(AppTheme.textSecondary)
            
            Text(dayNumber)
                .appFont(size: 16, weight: isSelected ? .bold : .regular)
                .foregroundColor(textColor)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(backgroundColor)
                )
        }
        .frame(maxWidth: .infinity)
        .onTapGesture {
            onTap()
        }
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if isToday {
            return AppTheme.accentBlue
        } else {
            return AppTheme.textPrimary
        }
    }
    
    private var backgroundColor: Color {
        if isSelected {
            return AppTheme.accentBlue
        } else if isToday {
            return AppTheme.accentBlue.opacity(0.1)
        } else {
            return Color.clear
        }
    }
}
