//
//  WeekRowView.swift
//  Nota
//
//  Created by GATHREAN DELA CRUZ on 2025-10-24.
//

import SwiftUI

struct WeekRowView: View {
    let weekStart: Date
    @Binding var selectedDate: Date
    
    private static let calendar: Calendar = {
        var cal = Calendar.current
        cal.firstWeekday = 1
        return cal
    }()
    
    private var weekDates: [Date] {
        (0..<7).compactMap { offset in
            Self.calendar.date(byAdding: .day, value: offset, to: weekStart)
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(weekDates, id: \.self) { date in
                WeekDayCell(
                    date: date,
                    isSelected: Self.calendar.isDate(date, inSameDayAs: selectedDate),
                    isToday: Self.calendar.isDateInToday(date),
                    onTap: {
                        withAnimation {
                            selectedDate = date
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 20)
    }
}
