//
//  ContentView.swift
//  ScheDue
//
//  Created by GATHREAN DELA CRUZ on 2025-10-19.
//
import SwiftUI

// Represents a single line/task
struct TaskLine: Identifiable {
    let id = UUID()
    var text: String
    var status: TaskStatus = .editing
}

enum TaskStatus {
    case editing        // User is typing
    case processing     // Being parsed
    case processed      // Successfully processed
}

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
                .tag(1)
        }
    }
}

// Home View - the notes input screen
struct HomeView: View {
    @State private var lines: [TaskLine] = [TaskLine(text: "")]
    @FocusState private var focusedLineId: UUID?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Divider()
                
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach($lines) { $line in
                            TaskLineRow(
                                line: $line,
                                isFocused: focusedLineId == line.id,
                                onSubmit: {
                                    handleLineSubmit(line)
                                },
                                onFocus: {
                                    focusedLineId = line.id
                                },
                                onInfoTap: {
                                    handleInfoTap(line)
                                },
                                onEdit: {
                                    handleEdit(line)
                                },
                                onDelete: {
                                    handleDelete(line)
                                },
                                onBackspaceOnEmpty: {
                                    handleBackspaceOnEmpty(line)
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("ScheDue")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                if let firstLine = lines.first {
                    focusedLineId = firstLine.id
                }
            }
        }
    }
    
    func handleLineSubmit(_ line: TaskLine) {
        guard !line.text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        if let index = lines.firstIndex(where: { $0.id == line.id }) {
            withAnimation(.easeInOut(duration: 0.2)) {
                lines[index].status = .processing
            }
            
            // Simulate processing
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if let idx = lines.firstIndex(where: { $0.id == line.id }) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        lines[idx].status = .processed
                    }
                }
            }
            
            // Remove any existing empty editing lines
            lines.removeAll { $0.text.isEmpty && $0.status == .editing }
            
            // Add new empty line and focus it
            let newLine = TaskLine(text: "")
            lines.append(newLine)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedLineId = newLine.id
            }
        }
    }
    
    func handleInfoTap(_ line: TaskLine) {
        print("ℹ️ Info tapped for: \(line.text)")
        // TODO: Open detail view showing what was parsed
    }
    
    func handleEdit(_ line: TaskLine) {
        if let index = lines.firstIndex(where: { $0.id == line.id }) {
            // Remove any existing empty editing lines first
            lines.removeAll { $0.text.isEmpty && $0.status == .editing }
            
            withAnimation(.easeInOut(duration: 0.2)) {
                lines[index].status = .editing
            }
            focusedLineId = line.id
        }
    }
    
    func handleDelete(_ line: TaskLine) {
        withAnimation {
            lines.removeAll { $0.id == line.id }
            
            // Ensure there's always at least one empty editing line
            if !lines.contains(where: { $0.text.isEmpty && $0.status == .editing }) {
                let newLine = TaskLine(text: "")
                lines.append(newLine)
                focusedLineId = newLine.id
            }
        }
    }
    
    func handleBackspaceOnEmpty(_ line: TaskLine) {
        // Find the previous line
        if let currentIndex = lines.firstIndex(where: { $0.id == line.id }),
           currentIndex > 0 {
            let previousLine = lines[currentIndex - 1]
            
            // Delete current empty line
//            withAnimation {
//                lines.remove(at: currentIndex)
//            }
            
            // If previous line is processed, make it editable
            if previousLine.status == .processed {
                handleEdit(previousLine)
            } else {
                // Just focus the previous line
                focusedLineId = previousLine.id
            }
        }
    }
}

// Individual line row
struct TaskLineRow: View {
    @Binding var line: TaskLine
    let isFocused: Bool
    let onSubmit: () -> Void
    let onFocus: () -> Void
    let onInfoTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onBackspaceOnEmpty: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("What's coming up next?", text: $line.text)
                .font(.body)
                .foregroundColor(lineTextColor)
                .disabled(line.status != .editing)
                .focused($isTextFieldFocused)
                .onSubmit {
                    onSubmit()
                }
                .onChange(of: line.text) { oldValue, newValue in
                    // Detect backspace on empty line
                    if oldValue.isEmpty && newValue.isEmpty && line.status == .editing {
                        // This fires when user presses backspace on empty field
                        // We'll handle this with a small delay to confirm it's backspace
                    }
                }
                .onChange(of: isTextFieldFocused) { _, newValue in
                    if newValue {
                        onFocus()
                    } else {
                        // When losing focus, check if line is empty and should trigger backspace behavior
                        if line.text.isEmpty && line.status == .editing && !newValue {
                            // User might be navigating with backspace
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if line.status == .processed {
                        onEdit()
                    }
                }
            
            // Right side icons
            HStack(spacing: 8) {
                if line.status == .processing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .transition(.scale.combined(with: .opacity))
                } else if line.status == .processed {
                    Button(action: onInfoTap) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 30)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(backgroundColor)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if line.status == .processed {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
        .onChange(of: isFocused) { _, newValue in
            isTextFieldFocused = newValue
        }
    }
    
    private var lineTextColor: Color {
        switch line.status {
        case .editing:
            return .primary
        case .processing, .processed:
            return .secondary
        }
    }
    
    private var backgroundColor: Color {
        line.status == .processed ? Color(.secondarySystemBackground) : Color.clear
    }
}

// Calendar View with sticky header
struct CalendarView: View {
    @State private var currentVisibleMonth = Date()
    @State private var scrollOffset: CGFloat = 0
    @Namespace private var scrollNamespace
    
    private let calendar = Calendar.current
    private let daysOfWeek = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    
    // Calculate month offset from year 2000
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
    
    // Calculate total months between 2000 and 2030
    private var totalMonths: Int {
        let components = calendar.dateComponents([.month], from: startDate, to: endDate)
        return (components.month ?? 0) + 1
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Sticky header with month/year and days of week
                VStack(spacing: 12) {
                    // Month and Year - BIGGER
                    Text(monthYearString)
                        .font(.system(size: 34, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Days of week
                    HStack(spacing: 0) {
                        ForEach(daysOfWeek, id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
                .background(Color(.systemBackground))
                
                Divider()
                
                // Scrollable months with offset tracking
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            // Generate all months from 2000 to 2030
                            ForEach(0..<totalMonths, id: \.self) { monthIndex in
                                if let monthDate = calendar.date(byAdding: .month, value: monthIndex, to: startDate) {
                                    MonthView(date: monthDate)
                                        .id(monthIndex)
                                        .background(
                                            GeometryReader { geo in
                                                Color.clear
                                                    .onChange(of: geo.frame(in: .named("scroll")).minY) { oldValue, newValue in
                                                        // Check if this month is near the top of the scroll view
                                                        if newValue > -50 && newValue < 150 {
                                                            if !calendar.isDate(currentVisibleMonth, equalTo: monthDate, toGranularity: .month) {
                                                                currentVisibleMonth = monthDate
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
                        // Scroll to current month on appear
                        scrollToToday(proxy: proxy)
                    }
                    .overlay(alignment: .bottom) {
                        // Today button
                        Button(action: {
                            scrollToToday(proxy: proxy)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.circle.fill")
                                    .font(.body)
                                Text("Today")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.blue)
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            )
                        }
                        .padding(.bottom, 20)
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
    
    private func scrollToToday(proxy: ScrollViewProxy) {
        // Calculate the month index for today
        let components = calendar.dateComponents([.month], from: startDate, to: Date())
        if let monthOffset = components.month {
            withAnimation(.easeInOut(duration: 0.5)) {
                proxy.scrollTo(monthOffset, anchor: .top)
            }
        }
    }
}

// Individual month view (simplified - no header)
struct MonthView: View {
    let date: Date
    
    private let calendar = Calendar.current
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(calendarDays, id: \.self) { cellDate in
                if let cellDate = cellDate {
                    DayCell(
                        date: cellDate,
                        isToday: isToday(cellDate),
                        isCurrentMonth: isCurrentMonth(cellDate)
                    )
                } else {
                    // Empty cell
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
        
        // Get the first day of the month
        let firstDayOfMonth = calendar.component(.weekday, from: monthInterval.start)
        
        // Add empty cells for days before the month starts
        for _ in 1..<firstDayOfMonth {
            days.append(nil)
        }
        
        // Add all days in the month
        let daysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 30
        for day in 0..<daysInMonth {
            if let dayDate = calendar.date(byAdding: .day, value: day, to: monthInterval.start) {
                days.append(dayDate)
            }
        }
        
        return days
    }
    
    private func isToday(_ checkDate: Date) -> Bool {
        calendar.isDateInToday(checkDate)
    }
    
    private func isCurrentMonth(_ checkDate: Date) -> Bool {
        calendar.isDate(checkDate, equalTo: date, toGranularity: .month)
    }
}

// Individual day cell in calendar
struct DayCell: View {
    let date: Date
    let isToday: Bool
    let isCurrentMonth: Bool
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // Today circle background
                if isToday {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 36, height: 36)
                }
                
                // Day number
                Text(dayNumber)
                    .font(.body)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundColor(isToday ? .white : (isCurrentMonth ? .primary : .secondary))
            }
            .frame(height: 36)
            
            // Placeholder for event indicator dots
            HStack(spacing: 2) {
                // TODO: Show dots for events on this day
                // Example: Circle().fill(Color.blue).frame(width: 4, height: 4)
            }
            .frame(height: 4)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ContentView()
}
