//
//  MonthGridView.swift
//  Nota
//
//  Created by GATHREAN DELA CRUZ on 2025-10-24.
//
import SwiftUI

struct MonthGridView: View {
    let date: Date
    let selectedDate: Date
    let isFullyVisible: Bool
    let onDateTap: (Date) -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(calendarDays, id: \.self) { cellDate in
                if let cellDate = cellDate {
                    SimpleDayCell(
                        date: cellDate,
                        isToday: calendar.isDateInToday(cellDate),
                        isSelected: calendar.isDate(cellDate, inSameDayAs: selectedDate),
                        isCurrentMonth: calendar.isDate(cellDate, equalTo: date, toGranularity: .month),
                        isFullyVisible: isFullyVisible,
                        onTap: {
                            onDateTap(cellDate)
                        }
                    )
                } else {
                    Color.clear
                        .frame(height: 44)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }
    
    private var calendarDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return []
        }
        
        var days: [Date?] = []
        let firstDayOfMonth = calendar.component(.weekday, from: monthInterval.start)
        
        for _ in 1..<firstDayOfMonth {
            days.append(nil)
        }
        
        let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
        for day in 0..<daysInMonth {
            if let dayDate = calendar.date(byAdding: .day, value: day, to: monthInterval.start) {
                days.append(dayDate)
            }
        }
        
        return days
    }
}
