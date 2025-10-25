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
    @State private var parsedNotification: (parsed: ParsedInput, targetDate: Date)?
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
            
            // Parsed task notification
            if let notification = parsedNotification {
                VStack {
                    Spacer()

                    // Simple test notification - replace with ParsedTaskNotification once verified
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(notification.parsed.intent == .event ? "Event" : "Task") added")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)

                                Text(shortDateString(notification.targetDate))
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.9))

                                if let time = notification.parsed.time {
                                    Text("Time: \(time)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }

                            Spacer()

                            Button(action: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    selectedDate = notification.targetDate
                                    currentWeekStart = Self.getWeekStart(for: notification.targetDate)
                                }
                                parsedNotification = nil
                            }) {
                                Text("Jump")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(AppTheme.accentBlue)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.white)
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding(16)
                    .background(notification.parsed.intent == .event ? Color.purple : AppTheme.accentBlue)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(true)
                .zIndex(100)
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
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: parsedNotification != nil)
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
                isUpdatingProgrammatically = true
                selectedDate = newDate
                DispatchQueue.main.async {
                    isUpdatingProgrammatically = false
                }
            }
        }
        .onChange(of: currentWeekStart) { oldValue, newValue in
                let normalized = Self.getWeekStart(for: newValue)
                if normalized != newValue {
                    currentWeekStart = normalized
                    return
                }
                
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
            guard !isUpdatingProgrammatically else { return }
            
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
        guard !line.text.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("⚠️ Empty line, skipping submit")
            return
        }

        print("📝 Submitting line: \(line.text)")
        print("📅 Current selected date: \(selectedDate)")

        // Parse the input
        let parsed = NaturalLanguageParser.shared.parse(line.text)
        print("🔍 Parsed result: intent=\(parsed.intent), date=\(String(describing: parsed.date)), time=\(String(describing: parsed.time)), location=\(String(describing: parsed.location)), confidence=\(parsed.confidence)")

        // Determine target date (use parsed date if available, otherwise current selected date)
        let targetDate = parsed.date != nil ? normalizedDate(parsed.date!) : normalizedDate(selectedDate)
        print("🎯 Target date (normalized): \(targetDate)")
        print("📊 Tasks by date dictionary before: \(tasksByDate.keys.map { shortDateString($0) })")

        // Find the line in the CURRENT date's lines (where it was typed)
        let currentNormalizedDate = normalizedDate(selectedDate)
        var currentLines = tasksByDate[currentNormalizedDate] ?? []
        print("📝 Current date lines count: \(currentLines.count)")

        if let index = currentLines.firstIndex(where: { $0.id == line.id }) {
            print("✅ Found line at index \(index)")

            // Create a copy of the line with parsed data
            var updatedLine = currentLines[index]
            updatedLine.parsedData = parsed
            updatedLine.status = .processing

            // If target date is different from current date, move the task
            if targetDate != currentNormalizedDate {
                print("🚚 Moving task from \(shortDateString(currentNormalizedDate)) to \(shortDateString(targetDate))")

                // Remove from current date
                currentLines.remove(at: index)

                // Add to target date
                var targetLines = tasksByDate[targetDate] ?? []
                targetLines.append(updatedLine)
                tasksByDate[targetDate] = targetLines

                print("📊 Task moved. Target date now has \(targetLines.count) tasks")
            } else {
                print("📍 Task staying at current date")
                currentLines[index] = updatedLine
            }

            // Update current date
            tasksByDate[currentNormalizedDate] = currentLines

            // Animate to processing
            withAnimation(.easeInOut(duration: 0.2)) {
                // Trigger UI update
                tasksByDate = tasksByDate
            }

            // After 1.5s, mark as processed
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                var targetLines = tasksByDate[targetDate] ?? []
                if let idx = targetLines.firstIndex(where: { $0.id == line.id }) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        targetLines[idx].status = .processed
                        tasksByDate[targetDate] = targetLines
                        print("✅ Task marked as processed on \(shortDateString(targetDate))")
                    }
                }
            }

            // Add new empty line to current date
            currentLines.removeAll { $0.text.isEmpty && $0.status == .editing }
            let newLine = TaskLine(text: "")
            currentLines.append(newLine)
            tasksByDate[currentNormalizedDate] = currentLines

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedLineId = newLine.id
            }

            // Show parsed notification
            print("🔔 About to set notification for date: \(targetDate)")
            print("🔔 parsedNotification BEFORE: \(parsedNotification == nil ? "nil" : "has value")")

            DispatchQueue.main.async {
                withAnimation {
                    parsedNotification = (parsed: parsed, targetDate: targetDate)
                }
                print("🔔 parsedNotification AFTER: \(parsedNotification == nil ? "nil" : "has value")")

                // Auto-dismiss after 5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    print("🔔 Auto-dismissing notification")
                    withAnimation {
                        parsedNotification = nil
                    }
                }
            }
        } else {
            print("❌ Could not find line with id \(line.id) in current date lines")
        }
    }
    
    func handleInfoTap(_ line: TaskLine) {
        guard let parsed = line.parsedData else {
            print("ℹ️ No parsed data available")
            return
        }

        var info = "Intent: \(parsed.intent)"
        if let date = parsed.date {
            info += "\nDate: \(shortDateString(date))"
        }
        if let time = parsed.time {
            info += "\nTime: \(time)"
        }
        if let location = parsed.location {
            info += "\nLocation: \(location)"
        }
        info += "\nConfidence: \(Int(parsed.confidence * 100))%"

        print("ℹ️ Parsed Info:\n\(info)")
        showToast(info)
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
