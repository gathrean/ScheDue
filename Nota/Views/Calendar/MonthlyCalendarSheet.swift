//
//  MonthlyCalendarSheet.swift
//  Nota
//
//  Created by GATHREAN DELA CRUZ on 2025-10-24.
//

import SwiftUI

struct MonthlyCalendarSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var selectedDate: Date
    @State private var currentVisibleMonth: Date
    @State private var hasScrolledToToday = false
    
    let onDateSelected: (Date) -> Void
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    
    private var startDate: Date {
        var components = DateComponents()
        components.year = 2000
        components.month = 1
        components.day = 1
        return calendar.date(from: components) ?? Date()
    }
    
    private var endDate: Date {
        var components = DateComponents()
        components.year = 2030
        components.month = 12
        components.day = 31
        return calendar.date(from: components) ?? Date()
    }
    
    private var totalMonths: Int {
        let components = calendar.dateComponents([.month], from: startDate, to: endDate)
        return (components.month ?? 0) + 1
    }
    
    private var todayMonthIndex: Int {
        let components = calendar.dateComponents([.month], from: startDate, to: Date())
        return components.month ?? 0
    }
    
    init(selectedDate: Binding<Date>, onDateSelected: @escaping (Date) -> Void) {
        self._selectedDate = selectedDate
        self._currentVisibleMonth = State(initialValue: selectedDate.wrappedValue)
        self.onDateSelected = onDateSelected
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Text(monthYearString)
                        .font(AppTheme.headerFont(size: 28))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    
                    HStack(spacing: 0) {
                        ForEach(daysOfWeek, id: \.self) { day in
                            Text(day)
                                .appFont(size: 12, weight: .semibold)
                                .foregroundColor(AppTheme.textSecondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
                .background(AppTheme.background)
                
                Divider()
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(0..<totalMonths, id: \.self) { monthIndex in
                                if let monthDate = calendar.date(byAdding: .month, value: monthIndex, to: startDate) {
                                    MonthGridView(
                                        date: monthDate,
                                        selectedDate: selectedDate,
                                        isFullyVisible: calendar.isDate(currentVisibleMonth, equalTo: monthDate, toGranularity: .month),
                                        onDateTap: { tappedDate in
                                            onDateSelected(tappedDate)
                                        }
                                    )
                                    .id(monthIndex)
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear
                                                .onChange(of: geo.frame(in: .named("scroll")).minY) { oldValue, newValue in
                                                    if newValue > -50 && newValue < 150 {
                                                        if !calendar.isDate(currentVisibleMonth, equalTo: monthDate, toGranularity: .month) {
                                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                                                currentVisibleMonth = monthDate
                                                            }
                                                        }
                                                    }
                                                }
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.vertical, 20)
                    }
                    .coordinateSpace(name: "scroll")
                    .onAppear {
                        if !hasScrolledToToday {
                            proxy.scrollTo(todayMonthIndex, anchor: .top)
                            hasScrolledToToday = true
                            currentVisibleMonth = Date()
                        }
                    }
                }
            }
            .background(AppTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Today") {
                        let today = Date()
                        onDateSelected(today)
                    }
                }
            }
        }
    }
    
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentVisibleMonth)
    }
}
