//
//  ContentView.swift
//  Nota
//
//  Created by GATHREAN DELA CRUZ on 2025-10-19.
//
import SwiftUI

// MARK: - App Theme
struct AppTheme {
    // Colors
    static let background = Color(hex: "e7e7e7")
    static let cardBackground = Color(.secondarySystemBackground)
    static let accentBlue = Color.blue
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    
    // Fonts
    static let fontDesign: Font.Design = .default  // Body text font
    
    // Header font helper
    static func headerFont(size: CGFloat, weight: Font.Weight = .bold) -> Font {
        return .custom("InstrumentSerif-Regular", size: size)
    }
    
    // Spacing
    static let paddingHorizontal: CGFloat = 20
    static let paddingVertical: CGFloat = 12
    
    // Calendar
    static let dayCellHeight: CGFloat = 80
}

// MARK: - App Font Modifier
struct AppFontModifier: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: weight, design: AppTheme.fontDesign))
    }
}

extension View {
    func appFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        modifier(AppFontModifier(size: size, weight: weight))
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Content View
struct ContentView: View {
    var body: some View {
        CalendarView()
            .preferredColorScheme(.light)
    }
}

// MARK: - Calendar View
struct CalendarView: View {
    @State private var currentVisibleMonth = Date()
    @State private var hasScrolledToToday = false
    @State private var toastMessage: String?
    @State private var newEventDate: Date?
    @State private var scrollToTodayTrigger = false
    @State private var selectedDate: Date? // NEW: Track selected date
    @State private var showDayDetail = false // NEW: Show day detail sheet
    
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
        components.year = 2100
        components.month = 12
        components.day = 31
        return calendar.date(from: components) ?? Date()
    }
    
    private var totalMonths: Int {
        let components = calendar.dateComponents([.month], from: startDate, to: endDate)
        return (components.month ?? 0) + 1
    }
    
    // Calculate today's month index on init
    private var todayMonthIndex: Int {
        let components = calendar.dateComponents([.month], from: startDate, to: Date())
        return components.month ?? 0
    }
    
    private var isViewingCurrentMonth: Bool {
        calendar.isDate(currentVisibleMonth, equalTo: Date(), toGranularity: .month)
    }
    
    var body: some View {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    VStack(spacing: 12) {
                        Text(monthYearString)
                            .font(AppTheme.headerFont(size: 34))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, AppTheme.paddingHorizontal)
                            .padding(.top, 20)
                        
                        HStack(spacing: 0) {
                            ForEach(daysOfWeek, id: \.self) { day in
                                Text(day)
                                    .appFont(size: 12, weight: .semibold)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.horizontal, AppTheme.paddingHorizontal)
                        .padding(.bottom, 8)
                    }
                    .background(AppTheme.background)
                    
                    Divider()
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(0..<totalMonths, id: \.self) { monthIndex in
                                    if let monthDate = calendar.date(byAdding: .month, value: monthIndex, to: startDate) {
                                        MonthView(
                                            date: monthDate,
                                            isFullyVisible: calendar.isDate(currentVisibleMonth, equalTo: monthDate, toGranularity: .month),
                                            highlightedDate: newEventDate,
                                            onDateTap: { tappedDate in
                                                selectedDate = tappedDate
                                                showDayDetail = true
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
                        .background(AppTheme.background)
                        .coordinateSpace(name: "scroll")
                        .onAppear {
                            if !hasScrolledToToday {
                                proxy.scrollTo(todayMonthIndex, anchor: .top)
                                hasScrolledToToday = true
                                currentVisibleMonth = Date()
                            }
                        }
                        .onChange(of: newEventDate) { oldValue, newValue in
                            if let eventDate = newValue {
                                scrollToDate(eventDate, proxy: proxy)
                            }
                        }
                        .onChange(of: scrollToTodayTrigger) { _, _ in
                            scrollToToday(proxy: proxy)
                        }
                    }
                }
                
                // Today button (bottom left) - REMOVED FAB
                HStack {
                    if !isViewingCurrentMonth {
                        Button(action: {
                            scrollToTodayTrigger.toggle()
                        }) {
                            HStack(spacing: 8) {
                                Text("Today")
                                    .appFont(size: 24, weight: .semibold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, AppTheme.paddingHorizontal)
                            .padding(.vertical, AppTheme.paddingVertical)
                            .background(
                                Capsule()
                                    .fill(AppTheme.accentBlue)
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            )
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .scale(scale: 0.9)),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                    }
                    
                    Spacer()
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isViewingCurrentMonth)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Toast notification
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
            .sheet(isPresented: $showDayDetail) {
                if let date = selectedDate {
                    DayDetailSheet(
                        selectedDate: date,
                        onEventAdded: { eventDate, eventText in
                            handleEventAdded(date: eventDate, text: eventText)
                        }
                    )
                }
            }
        }
        
        private var monthYearString: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: currentVisibleMonth)
        }
        
        private func scrollToToday(proxy: ScrollViewProxy) {
            withAnimation(.easeInOut(duration: 0.5)) {
                proxy.scrollTo(todayMonthIndex, anchor: .top)
            }
        }
        
        private func scrollToDate(_ date: Date, proxy: ScrollViewProxy) {
            let components = calendar.dateComponents([.month], from: startDate, to: date)
            if let monthOffset = components.month {
                withAnimation(.easeInOut(duration: 0.5)) {
                    proxy.scrollTo(monthOffset, anchor: .top)
                }
            }
        }
        
        private func handleEventAdded(date: Date, text: String) {
            // Highlight the date with animation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                newEventDate = date
            }
            
            // Show toast
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            toastMessage = "Added to \(formatter.string(from: date))"
            
            // Clear toast after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    toastMessage = nil
                }
            }
            
            // Clear highlight after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    newEventDate = nil
                }
            }
        }
    }

// MARK: - Month View
struct MonthView: View {
    let date: Date
    let isFullyVisible: Bool
    let highlightedDate: Date?
    let onDateTap: (Date) -> Void
    
    private let calendar = Calendar.current
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(calendarDays, id: \.self) { cellDate in
                if let cellDate = cellDate {
                    DayCell(
                        date: cellDate,
                        isToday: isToday(cellDate),
                        isCurrentMonth: isCurrentMonth(cellDate),
                        isFullyVisible: isFullyVisible,
                        isHighlighted: isHighlighted(cellDate),
                        onTap: {
                            onDateTap(cellDate)
                        }
                    )
                } else {
                    Color.clear
                        .frame(height: AppTheme.dayCellHeight)
                }
            }
        }
        .padding(.horizontal, AppTheme.paddingHorizontal)
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
    
    private func isToday(_ checkDate: Date) -> Bool {
        calendar.isDateInToday(checkDate)
    }
    
    private func isCurrentMonth(_ checkDate: Date) -> Bool {
        calendar.isDate(checkDate, equalTo: date, toGranularity: .month)
    }
    
    private func isHighlighted(_ checkDate: Date) -> Bool {
            guard let highlightedDate = highlightedDate else { return false }
            return calendar.isDate(checkDate, inSameDayAs: highlightedDate)
        }
    }

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let isToday: Bool
    let isCurrentMonth: Bool
    let isFullyVisible: Bool
    let isHighlighted: Bool
    let onTap: () -> Void // NEW: Tap callback
    
    @State private var showDot = false
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 1)
            
            Spacer()
            
            ZStack {
                if isToday {
                    Circle()
                        .fill(AppTheme.accentBlue)
                        .frame(width: 36, height: 36)
                }
                
                Text(dayNumber)
                    .appFont(size: 17, weight: isToday ? .bold : .regular)
                    .foregroundColor(textColor)
            }
            .frame(height: 36)
            
            Spacer()
            
            VStack(spacing: 2) {
                if showDot {
                    Circle()
                        .fill(AppTheme.accentBlue)
                        .frame(width: 6, height: 6)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(minHeight: 20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: AppTheme.dayCellHeight)
        .contentShape(Rectangle()) // Makes entire cell tappable
        .onTapGesture {
            onTap()
        }
        .onChange(of: isHighlighted) { oldValue, newValue in
            if newValue {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    showDot = true
                }
            }
        }
    }
    
    private var textColor: Color {
        if isToday {
            return .white
        } else if !isCurrentMonth {
            return AppTheme.textSecondary
        } else if isFullyVisible {
            return AppTheme.textPrimary
        } else {
            return AppTheme.textPrimary.opacity(0.4)
        }
    }
}

// MARK: - Day Detail Sheet
struct DayDetailSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedDate: Date
    @State private var lines: [TaskLine] = [TaskLine(text: "")]
    @State private var currentWeekStart: Date
    @FocusState private var focusedLineId: UUID?
    
    let onEventAdded: (Date, String) -> Void
    
    private let calendar = Calendar.current
    
    init(selectedDate: Date, onEventAdded: @escaping (Date, String) -> Void) {
        let normalizedDate = Calendar.current.startOfDay(for: selectedDate)
        self._selectedDate = State(initialValue: normalizedDate)
        self._currentWeekStart = State(initialValue: Self.getWeekStart(for: normalizedDate))
        self.onEventAdded = onEventAdded
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Spacer for drag indicator
            Color.clear
                .frame(height: 12)
            
            // Horizontal week view
            WeekScrollView(
                currentWeekStart: $currentWeekStart,
                selectedDate: $selectedDate
            )
            
            Divider()
                .padding(.vertical, 8)
            
            // Selected date header
            Text(selectedDateString)
                .appFont(size: 20, weight: .semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            
            // Tasks for this date
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
                            }
                        )
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 20)
            }
        }
        .background(AppTheme.background)
        .onAppear {
            if let firstLine = lines.first {
                focusedLineId = firstLine.id
            }
        }
        .onChange(of: selectedDate) { oldValue, newValue in
            // Update week if date changed to different week
            let newWeekStart = Self.getWeekStart(for: newValue)
            if newWeekStart != currentWeekStart {
                withAnimation {
                    currentWeekStart = newWeekStart
                }
            }
            
            // TODO: Load tasks for the new selected date
        }
    }
    
    private var selectedDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private static func getWeekStart(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }
    
    // ... (copy all the handle functions from QuickAddSheet: handleLineSubmit, handleInfoTap, handleEdit, handleDelete)
    
    func handleLineSubmit(_ line: TaskLine) {
        guard !line.text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        if let index = lines.firstIndex(where: { $0.id == line.id }) {
            withAnimation(.easeInOut(duration: 0.2)) {
                lines[index].status = .processing
            }
            
            // Parse and add to calendar
            _ = parseText(line.text)
            onEventAdded(selectedDate, line.text)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if let idx = lines.firstIndex(where: { $0.id == line.id }) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        lines[idx].status = .processed
                    }
                }
            }
            
            lines.removeAll { $0.text.isEmpty && $0.status == .editing }
            
            let newLine = TaskLine(text: "")
            lines.append(newLine)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedLineId = newLine.id
            }
        }
    }
    
    func handleInfoTap(_ line: TaskLine) {
        print("ℹ️ Info tapped for: \(line.text)")
    }
    
    func handleEdit(_ line: TaskLine) {
        if let index = lines.firstIndex(where: { $0.id == line.id }) {
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
            
            if !lines.contains(where: { $0.text.isEmpty && $0.status == .editing }) {
                let newLine = TaskLine(text: "")
                lines.append(newLine)
                focusedLineId = newLine.id
            }
        }
    }
    
    private func parseText(_ text: String) -> ParsedEvent {
        if text.lowercased().contains("tomorrow") {
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            return ParsedEvent(
                title: text,
                date: tomorrow,
                type: .event,
                time: "2:00 PM"
            )
        }
        
        return ParsedEvent(
            title: text,
            date: Date(),
            type: .event,
            time: nil
        )
    }
}
//
//// MARK: - Day Detail Sheet
//struct DayDetailSheet: View {
//    @Environment(\.dismiss) var dismiss
//    @State private var selectedDate: Date
//    @State private var lines: [TaskLine] = [TaskLine(text: "")]
//    @State private var currentWeekStart: Date
//    @FocusState private var focusedLineId: UUID?
//    
//    let onEventAdded: (Date, String) -> Void
//    
//    private let calendar = Calendar.current
//    
//    init(selectedDate: Date, onEventAdded: @escaping (Date, String) -> Void) {
//        let normalizedDate = Calendar.current.startOfDay(for: selectedDate)
//        self._selectedDate = State(initialValue: normalizedDate)
//        self._currentWeekStart = State(initialValue: Self.getWeekStart(for: normalizedDate))
//        self.onEventAdded = onEventAdded
//    }
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            // Spacer for drag indicator
//            Color.clear
//                .frame(height: 12)
//            
//            // Horizontal week view
//            WeekScrollView(
//                currentWeekStart: $currentWeekStart,
//                selectedDate: $selectedDate
//            )
//            
//            Divider()
//                .padding(.vertical, 8)
//            
//            // Selected date header
//            Text(selectedDateString)
//                .appFont(size: 20, weight: .semibold)
//                .frame(maxWidth: .infinity, alignment: .leading)
//                .padding(.horizontal, 20)
//                .padding(.bottom, 12)
//            
//            // Tasks for this date
//            ScrollView {
//                VStack(spacing: 0) {
//                    ForEach($lines) { $line in
//                        TaskLineRow(
//                            line: $line,
//                            isFocused: focusedLineId == line.id,
//                            onSubmit: {
//                                handleLineSubmit(line)
//                            },
//                            onFocus: {
//                                focusedLineId = line.id
//                            },
//                            onInfoTap: {
//                                handleInfoTap(line)
//                            },
//                            onEdit: {
//                                handleEdit(line)
//                            },
//                            onDelete: {
//                                handleDelete(line)
//                            }
//                        )
//                    }
//                }
//                .padding(.top, 8)
//                .padding(.bottom, 20)
//            }
//        }
//        .background(AppTheme.background)
//        .onAppear {
//            if let firstLine = lines.first {
//                focusedLineId = firstLine.id
//            }
//        }
//        .onChange(of: selectedDate) { oldValue, newValue in
//            // Update week if date changed to different week
//            let newWeekStart = Self.getWeekStart(for: newValue)
//            if newWeekStart != currentWeekStart {
//                withAnimation {
//                    currentWeekStart = newWeekStart
//                }
//            }
//            
//            // TODO: Load tasks for the new selected date
//        }
//    }
//    
//    private var selectedDateString: String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "EEEE, MMM d, yyyy"
//        return formatter.string(from: selectedDate)
//    }
//    
//    private static func getWeekStart(for date: Date) -> Date {
//        let calendar = Calendar.current
//        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
//        return calendar.date(from: components) ?? date
//    }
//    
//    // ... (copy all the handle functions from QuickAddSheet: handleLineSubmit, handleInfoTap, handleEdit, handleDelete)
//    
//    func handleLineSubmit(_ line: TaskLine) {
//        guard !line.text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
//        
//        if let index = lines.firstIndex(where: { $0.id == line.id }) {
//            withAnimation(.easeInOut(duration: 0.2)) {
//                lines[index].status = .processing
//            }
//            
//            // Parse and add to calendar
//            let event = parseText(line.text)
//            onEventAdded(selectedDate, line.text)
//            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//                if let idx = lines.firstIndex(where: { $0.id == line.id }) {
//                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
//                        lines[idx].status = .processed
//                    }
//                }
//            }
//            
//            lines.removeAll { $0.text.isEmpty && $0.status == .editing }
//            
//            let newLine = TaskLine(text: "")
//            lines.append(newLine)
//            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                focusedLineId = newLine.id
//            }
//        }
//    }
//    
//    func handleInfoTap(_ line: TaskLine) {
//        print("ℹ️ Info tapped for: \(line.text)")
//    }
//    
//    func handleEdit(_ line: TaskLine) {
//        if let index = lines.firstIndex(where: { $0.id == line.id }) {
//            lines.removeAll { $0.text.isEmpty && $0.status == .editing }
//            
//            withAnimation(.easeInOut(duration: 0.2)) {
//                lines[index].status = .editing
//            }
//            focusedLineId = line.id
//        }
//    }
//    
//    func handleDelete(_ line: TaskLine) {
//        withAnimation {
//            lines.removeAll { $0.id == line.id }
//            
//            if !lines.contains(where: { $0.text.isEmpty && $0.status == .editing }) {
//                let newLine = TaskLine(text: "")
//                lines.append(newLine)
//                focusedLineId = newLine.id
//            }
//        }
//    }
//    
//    private func parseText(_ text: String) -> ParsedEvent {
//        if text.lowercased().contains("tomorrow") {
//            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
//            return ParsedEvent(
//                title: text,
//                date: tomorrow,
//                type: .event,
//                time: "2:00 PM"
//            )
//        }
//        
//        return ParsedEvent(
//            title: text,
//            date: Date(),
//            type: .event,
//            time: nil
//        )
//    }
//}

// MARK: - Week Scroll View
struct WeekScrollView: View {
    @Binding var currentWeekStart: Date
    @Binding var selectedDate: Date
    
    private let calendar = Calendar.current
    
    private var weekDates: [Date] {
        (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: currentWeekStart)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Week navigation
            HStack {
                Button(action: previousWeek) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                
                Spacer()
                
                Text(weekRangeString)
                    .appFont(size: 14, weight: .medium)
                    .foregroundColor(AppTheme.textSecondary)
                
                Spacer()
                
                Button(action: nextWeek) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
            .padding(.horizontal, 20)
            
            // Days of week
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
        .padding(.vertical, 12)
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
    
    private func previousWeek() {
        if let newWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart) {
            withAnimation {
                currentWeekStart = newWeekStart
            }
        }
    }
    
    private func nextWeek() {
        if let newWeekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeekStart) {
            withAnimation {
                currentWeekStart = newWeekStart
            }
        }
    }
}

// MARK: - Week Day Cell
struct WeekDayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void
    
    private let calendar = Calendar.current
    
    private var dayLetter: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return String(formatter.string(from: date).prefix(1))
    }
    
    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayLetter)
                .appFont(size: 12, weight: .medium)
                .foregroundColor(AppTheme.textSecondary)
            
            Text(dayNumber)
                .appFont(size: 16, weight: isSelected ? .bold : .regular)
                .foregroundColor(textColor)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(backgroundColor)
                )
        }
        .frame(maxWidth: .infinity)
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
}

// MARK: - Toast View
struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .appFont(size: 15, weight: .medium)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.8))
            )
    }
}

// MARK: - Task Line
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

// MARK: - Task Line Row
struct TaskLineRow: View {
    @Binding var line: TaskLine
    let isFocused: Bool
    let onSubmit: () -> Void
    let onFocus: () -> Void
    let onInfoTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("What's coming up next?", text: $line.text)
                .appFont(size: 17)
                .foregroundColor(lineTextColor)
                .disabled(line.status != .editing)
                .focused($isTextFieldFocused)
                .onSubmit {
                    onSubmit()
                }
                .onChange(of: isTextFieldFocused) { _, newValue in
                    if newValue {
                        onFocus()
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if line.status == .processed {
                        onEdit()
                    }
                }
            
            HStack(spacing: 8) {
                if line.status == .processing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .transition(.scale.combined(with: .opacity))
                } else if line.status == .processed {
                    Button(action: onInfoTap) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(AppTheme.accentBlue)
                            .font(.title3)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: 30)
        }
        .padding(.horizontal, AppTheme.paddingHorizontal)
        .padding(.vertical, AppTheme.paddingVertical)
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
            return AppTheme.textPrimary
        case .processing, .processed:
            return AppTheme.textSecondary
        }
    }
    
    private var backgroundColor: Color {
        line.status == .processed ? AppTheme.cardBackground : Color.clear
    }
}

//// MARK: - Quick Add Sheet
//struct QuickAddSheet: View {
//    @Environment(\.dismiss) var dismiss
//    @Binding var sheetDetent: PresentationDetent
//    @State private var lines: [TaskLine] = [TaskLine(text: "")]
//    @FocusState private var focusedLineId: UUID?
//    
//    let onEventAdded: (Date, String) -> Void
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            ScrollView {
//                VStack(spacing: 0) {
//                    ForEach($lines) { $line in
//                        TaskLineRow(
//                            line: $line,
//                            isFocused: focusedLineId == line.id,
//                            onSubmit: {
//                                handleLineSubmit(line)
//                            },
//                            onFocus: {
//                                focusedLineId = line.id
//                            },
//                            onInfoTap: {
//                                handleInfoTap(line)
//                            },
//                            onEdit: {
//                                handleEdit(line)
//                            },
//                            onDelete: {
//                                handleDelete(line)
//                            }
//                        )
//                    }
//                }
//                .padding(.top, 30)
//                .padding(.bottom, 30)
//            }
//        }
//        .background(AppTheme.background)
//        .onAppear {
//            if let firstLine = lines.first {
//                focusedLineId = firstLine.id
//            }
//        }
//    }
//    
//    func handleLineSubmit(_ line: TaskLine) {
//        guard !line.text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
//        
//        if let index = lines.firstIndex(where: { $0.id == line.id }) {
//            withAnimation(.easeInOut(duration: 0.2)) {
//                lines[index].status = .processing
//            }
//            
//            // Parse and add to calendar
//            let event = parseText(line.text)
//            onEventAdded(event.date, line.text)
//            
//            // Simulate processing
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//                if let idx = lines.firstIndex(where: { $0.id == line.id }) {
//                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
//                        lines[idx].status = .processed
//                    }
//                }
//            }
//            
//            // Remove any existing empty editing lines
//            lines.removeAll { $0.text.isEmpty && $0.status == .editing }
//            
//            // Add new empty line and focus it
//            let newLine = TaskLine(text: "")
//            lines.append(newLine)
//            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                focusedLineId = newLine.id
//            }
//        }
//    }
//    
//    func handleInfoTap(_ line: TaskLine) {
//        print("ℹ️ Info tapped for: \(line.text)")
//        // TODO: Show parsed details
//    }
//    
//    func handleEdit(_ line: TaskLine) {
//        if let index = lines.firstIndex(where: { $0.id == line.id }) {
//            lines.removeAll { $0.text.isEmpty && $0.status == .editing }
//            
//            withAnimation(.easeInOut(duration: 0.2)) {
//                lines[index].status = .editing
//            }
//            focusedLineId = line.id
//        }
//    }
//    
//    func handleDelete(_ line: TaskLine) {
//        withAnimation {
//            lines.removeAll { $0.id == line.id }
//            
//            if !lines.contains(where: { $0.text.isEmpty && $0.status == .editing }) {
//                let newLine = TaskLine(text: "")
//                lines.append(newLine)
//                focusedLineId = newLine.id
//            }
//        }
//    }
//    
//    private func parseText(_ text: String) -> ParsedEvent {
//        if text.lowercased().contains("tomorrow") {
//            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
//            return ParsedEvent(
//                title: text,
//                date: tomorrow,
//                type: .event,
//                time: "2:00 PM"
//            )
//        }
//        
//        return ParsedEvent(
//            title: text,
//            date: Date(),
//            type: .event,
//            time: nil
//        )
//    }
//}

// MARK: - Parsed Event Model
struct ParsedEvent {
    let title: String
    let date: Date
    let type: EventType
    let time: String?
    
    enum EventType {
        case event
        case task
    }
}

// MARK: - #Preview
#Preview {
    ContentView()
}
