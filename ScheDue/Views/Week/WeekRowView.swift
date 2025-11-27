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
    @EnvironmentObject var taskStore: TaskDataStore

    private static let calendar: Calendar = {
        var cal = Calendar.current
        cal.firstWeekday = 1
        return cal
    }()

    private func normalizedDate(_ date: Date) -> Date {
        Self.calendar.startOfDay(for: date)
    }

    private func tasksCount(for date: Date) -> Int {
        let normalized = normalizedDate(date)
        // Filter out empty editing lines
        let tasks = taskStore.tasksByDate[normalized]?.filter { task in
            !task.text.isEmpty || task.status != .editing
        } ?? []
        return tasks.count
    }

    private func hasEvents(for date: Date) -> Bool {
        let normalized = normalizedDate(date)
        // Filter out empty editing lines
        let tasks = taskStore.tasksByDate[normalized]?.filter { task in
            !task.text.isEmpty || task.status != .editing
        } ?? []
        return tasks.contains(where: { $0.isEvent })
    }
    
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
                    taskCount: tasksCount(for: date),
                    hasEvents: hasEvents(for: date),
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
