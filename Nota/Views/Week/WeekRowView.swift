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
    
    private let calendar = Calendar.current
    
    private var weekDates: [Date] {
        (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: weekStart)
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(weekDates, id: \.self) { date in
                WeekDayCell(
                    date: date,
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                    isToday: calendar.isDateInToday(date),
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
