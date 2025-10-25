//
//  WeekScrollView.swift
//  Nota
//
//  Created by GATHREAN DELA CRUZ on 2025-10-24.
//

import SwiftUI

struct WeekScrollView: View {
    @Binding var currentWeekStart: Date
    @Binding var selectedDate: Date
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.firstWeekday = 1 // 1 = Sunday
        return cal
    }
    
    private var weeks: [Date] {
        let weeksToShow = 52 * 5
        let startOffset = -weeksToShow / 2
        
        return (startOffset...(weeksToShow / 2)).compactMap { weekOffset in
            calendar.date(byAdding: .weekOfYear, value: weekOffset, to: currentWeekStart)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(weekRangeString)
                .appFont(size: 14, weight: .medium)
                .foregroundColor(AppTheme.textSecondary)
                .padding(.top, 12)

            GeometryReader { geometry in
                TabView(selection: $currentWeekStart) {
                    ForEach(weeks, id: \.self) { weekStart in
                        WeekRowView(
                            weekStart: weekStart,
                            selectedDate: $selectedDate
                        )
                        .frame(width: geometry.size.width, height: 80, alignment: .center)
                        .tag(weekStart)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .frame(height: 80)
        }
        .padding(.bottom, 8)
    }
    
    private var weekRangeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: currentWeekStart) else {
            return ""
        }
        
        let startString = formatter.string(from: currentWeekStart)
        let endString = formatter.string(from: weekEnd)
        
        return "\(startString) - \(endString)"
    }
}
