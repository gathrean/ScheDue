//
//  WeekTaskView.swift
//  Nota
//
//  Created by GATHREAN DELA CRUZ on 2025-10-24.
//

import SwiftUI

struct WeekTaskView: View {
    @State private var selectedDate = Date()
    @State private var currentWeekStart: Date
    @State private var tasksByDate: [Date: [TaskLine]] = [:]
    @State private var showMonthlyCalendar = false
    @State private var toastMessage: String?
    @FocusState private var focusedLineId: UUID?
    @State private var isUpdatingProgrammatically = false
    
    private static let calendar: Calendar = {
            var cal = Calendar.current
            cal.firstWeekday = 1 // 1 = Sunday
            return cal
        }()
    
    init() {
        let today = Date()
        let weekStart = Self.getWeekStart(for: today)
        self._selectedDate = State(initialValue: today)
        self._currentWeekStart = State(initialValue: weekStart)
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Nota")
                        .font(AppTheme.headerFont(size: 34))
                    
                    Spacer()
                    
                    Button(action: {
                        showMonthlyCalendar = true
                    }) {
                        Image(systemName: "calendar")
                            .font(.system(size: 24, weight: .regular))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
                
                Divider()
                
                // Week scroll
                WeekScrollView(
                    currentWeekStart: $currentWeekStart,
                    selectedDate: $selectedDate
                )
                
                Divider()
                    .padding(.vertical, 8)
                
                // Selected date
                Text(selectedDateString)
                    .appFont(size: 20, weight: .semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                
                // Tasks for selected date
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(linesBinding) { $line in
                            TaskLineRow(
                                line: $line,
                                isFocused: focusedLineId == line.id,
                                onSubmit: { handleLineSubmit(line) },
                                onFocus: { focusedLineId = line.id },
                                onInfoTap: { handleInfoTap(line) },
                                onEdit: { handleEdit(line) },
                                onDelete: { handleDelete(line) }
                            )
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                }
                .background(AppTheme.background)
            }
            .background(AppTheme.background)
            
            // Today button
            if !isViewingToday {
                Button(action: jumpToToday) {
                    Text("Today")
                        .appFont(size: 16, weight: .semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(AppTheme.accentBlue)
                                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                        )
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .scale(scale: 0.9)),
                    removal: .move(edge: .bottom).combined(with: .opacity)
                ))
            }
            
            // Toast
            if let message = toastMessage {
                VStack {
                    Spacer()
                    ToastView(message: message)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isViewingToday)
        .sheet(isPresented: $showMonthlyCalendar) {
            MonthlyCalendarSheet(
                selectedDate: $selectedDate,
                onDateSelected: { newDate in
                    selectedDate = newDate
                    currentWeekStart = Self.getWeekStart(for: newDate)
                    showMonthlyCalendar = false
                }
            )
        }
        .onAppear {
            // Ensure current date has at least one empty line
            ensureEmptyLineExists()
            
            // Focus first line
            if let firstLine = getCurrentLines().first {
                focusedLineId = firstLine.id
            }
        }
        
        .onChange(of: currentWeekStart) { oldValue, newValue in
            guard oldValue != newValue else { return }
            
            let dayOffset = Self.calendar.dateComponents([.day],
                                                    from: Self.getWeekStart(for: selectedDate),
                                                    to: selectedDate).day ?? 0
            
            if let newDate = Self.calendar.date(byAdding: .day, value: dayOffset, to: newValue) {
                isUpdatingProgrammatically = true  // ← ADD
                selectedDate = newDate
                DispatchQueue.main.async {
                    isUpdatingProgrammatically = false  // ← ADD
                }
            }
        }
        .onChange(of: currentWeekStart) { oldValue, newValue in
                // First handler: Normalize currentWeekStart if it's not a proper week start
                let normalized = Self.getWeekStart(for: newValue)
                if normalized != newValue {
                    // This shouldn't trigger recursion since we check they're different
                    currentWeekStart = normalized
                    return // Skip the rest of this handler
                }
                
                // Continue with existing logic only if already normalized
                guard oldValue != newValue else { return }

                let dayOffset = Self.calendar.dateComponents([.day],
                    from: Self.getWeekStart(for: selectedDate),
                    to: selectedDate).day ?? 0

                if let newDate = Self.calendar.date(byAdding: .day, value: dayOffset, to: newValue) {
                    isUpdatingProgrammatically = true
                    selectedDate = newDate
                    DispatchQueue.main.async {
                        isUpdatingProgrammatically = false
                    }
                }
            }
        .onChange(of: selectedDate) { oldValue, newValue in
            guard !isUpdatingProgrammatically else { return }  // ← ADD THIS LINE
            
            let newWeekStart = Self.getWeekStart(for: newValue)
            if newWeekStart != currentWeekStart {
                withAnimation {
                    currentWeekStart = newWeekStart
                }
            }
            
            ensureEmptyLineExists()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let firstLine = getCurrentLines().first {
                    focusedLineId = firstLine.id
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private var isViewingToday: Bool {
        Self.calendar.isDateInToday(selectedDate)
    }
    
    private static func getWeekStart(for date: Date) -> Date {
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) else {
                return calendar.startOfDay(for: date)
            }
            return calendar.startOfDay(for: weekInterval.start)
        }
    
    private func jumpToToday() {
        let today = Date()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            selectedDate = today
            currentWeekStart = Self.getWeekStart(for: today)
        }
    }
    
    private func normalizedDate(_ date: Date) -> Date {
        Self.calendar.startOfDay(for: date)
    }
    
    private func getCurrentLines() -> [TaskLine] {
        let normalizedDate = normalizedDate(selectedDate)
        return tasksByDate[normalizedDate] ?? []
    }
    
    private func ensureEmptyLineExists() {
        let normalizedDate = normalizedDate(selectedDate)
        var lines = tasksByDate[normalizedDate] ?? []
        
        // If no lines exist, or no empty editing line exists, add one
        if lines.isEmpty || !lines.contains(where: { $0.text.isEmpty && $0.status == .editing }) {
            lines.append(TaskLine(text: ""))
            tasksByDate[normalizedDate] = lines
        }
    }
    
    // Create binding for the lines array
    private var linesBinding: Binding<[TaskLine]> {
        let normalizedDate = normalizedDate(selectedDate)
        return Binding(
            get: {
                tasksByDate[normalizedDate] ?? [TaskLine(text: "")]
            },
            set: { newValue in
                tasksByDate[normalizedDate] = newValue
            }
        )
    }
    
    // MARK: - Task Management
    
    func handleLineSubmit(_ line: TaskLine) {
        guard !line.text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let normalizedDate = normalizedDate(selectedDate)
        var lines = tasksByDate[normalizedDate] ?? []
        
        if let index = lines.firstIndex(where: { $0.id == line.id }) {
            withAnimation(.easeInOut(duration: 0.2)) {
                lines[index].status = .processing
                tasksByDate[normalizedDate] = lines
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                var updatedLines = tasksByDate[normalizedDate] ?? []
                if let idx = updatedLines.firstIndex(where: { $0.id == line.id }) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        updatedLines[idx].status = .processed
                        tasksByDate[normalizedDate] = updatedLines
                    }
                }
            }
            
            // Remove empty editing lines
            lines.removeAll { $0.text.isEmpty && $0.status == .editing }
            
            // Add new empty line
            let newLine = TaskLine(text: "")
            lines.append(newLine)
            tasksByDate[normalizedDate] = lines
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedLineId = newLine.id
            }
            
            showToast("Added to \(shortDateString(selectedDate))")
        }
    }
    
    func handleInfoTap(_ line: TaskLine) {
        print("ℹ️ Info tapped for: \(line.text)")
    }
    
    func handleEdit(_ line: TaskLine) {
        let normalizedDate = normalizedDate(selectedDate)
        var lines = tasksByDate[normalizedDate] ?? []
        
        if let index = lines.firstIndex(where: { $0.id == line.id }) {
            lines.removeAll { $0.text.isEmpty && $0.status == .editing }
            
            withAnimation(.easeInOut(duration: 0.2)) {
                lines[index].status = .editing
                tasksByDate[normalizedDate] = lines
            }
            focusedLineId = line.id
        }
    }
    
    func handleDelete(_ line: TaskLine) {
        let normalizedDate = normalizedDate(selectedDate)
        var lines = tasksByDate[normalizedDate] ?? []
        
        withAnimation {
            lines.removeAll { $0.id == line.id }
            
            if !lines.contains(where: { $0.text.isEmpty && $0.status == .editing }) {
                let newLine = TaskLine(text: "")
                lines.append(newLine)
                focusedLineId = newLine.id
            }
            
            tasksByDate[normalizedDate] = lines
        }
    }
    
    private func showToast(_ message: String) {
        withAnimation {
            toastMessage = message
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                toastMessage = nil
            }
        }
    }
    
    private func shortDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}
