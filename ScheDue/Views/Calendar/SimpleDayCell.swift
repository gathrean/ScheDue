//
//  SimpleDayCell.swift
//  Nota
//
//  Created by GATHREAN DELA CRUZ on 2025-10-24.
//

import SwiftUI

struct SimpleDayCell: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let isCurrentMonth: Bool
    let isFullyVisible: Bool
    let onTap: () -> Void
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        Text(dayNumber)
            .appFont(size: 16, weight: isSelected ? .bold : .regular)
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                Circle()
                    .fill(backgroundColor)
                    .padding(4)
            )
            .overlay(
                Circle()
                    .stroke(isToday && !isSelected ? AppTheme.accentBlue : Color.clear, lineWidth: 2)
                    .padding(4)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
    }
    
    private var textColor: Color {
        if isSelected {
            return .white
        } else if !isCurrentMonth {
            return AppTheme.textSecondary
        } else if isFullyVisible {
            return AppTheme.textPrimary
        } else {
            return AppTheme.textPrimary.opacity(0.4)
        }
    }
    
    private var backgroundColor: Color {
        isSelected ? AppTheme.accentBlue : Color.clear
    }
}
