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
    let taskCount: Int
    let hasEvents: Bool
    let onTap: () -> Void
    
    private var dayLetter: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(1))
    }

    private var isWeekday: Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        // weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        return weekday >= 2 && weekday <= 6
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayLetter)
                .font(.system(size: 12, weight: isWeekday ? .heavy : .medium, design: .default))
                .foregroundColor(AppTheme.textSecondary)

            VStack(spacing: 2) {
                Text(dayNumber)
                    .font(.system(size: 16, weight: isSelected ? .bold : .regular, design: .default))
                    .foregroundColor(textColor)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(backgroundColor)
                    )

                // Event/Task indicators
                if taskCount > 0 {
                    HStack(spacing: 2) {
                        Circle()
                            .fill(indicatorColor)
                            .frame(width: 4, height: 4)

                        if taskCount > 1 {
                            Text("\(taskCount)")
                                .font(.system(size: 8, weight: .semibold))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                    }
                    .frame(height: 6)
                } else {
                    Spacer()
                        .frame(height: 6)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
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

    private var indicatorColor: Color {
        if hasEvents {
            return Color.purple
        } else {
            return AppTheme.accentBlue
        }
    }
}
