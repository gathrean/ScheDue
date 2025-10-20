//
//  ContentView.swift
//  ScheDue
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
    @State private var showQuickAdd = false
    @State private var toastMessage: String?
    @State private var newEventDate: Date?
    @State private var sheetDetent: PresentationDetent = .fraction(0.33)
    @State private var scrollToTodayTrigger = false
    
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
                                            highlightedDate: newEventDate
                                        )
                                        .id(monthIndex)
                                        .background(
                                            GeometryReader { geo in
                                                Color.clear
                                                    .onChange(of: geo.frame(in: .named("scroll")).minY) { oldValue, newValue in
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
                
                // Bottom buttons row
                HStack {
                    // Today button (bottom left)
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
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isViewingCurrentMonth)
                    }
                    
                    Spacer()
                    
                    // Floating Action Button (bottom right)
                    Button(action: {
                        showQuickAdd = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(AppTheme.accentBlue)
                                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                    }
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
            .sheet(isPresented: $showQuickAdd) {
                QuickAddSheet(
                    sheetDetent: $sheetDetent,
                    onEventAdded: { date, eventText in
                        handleEventAdded(date: date, text: eventText)
                    }
                )
                .presentationDetents([.fraction(0.33), .large], selection: $sheetDetent)
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .large))
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
                        isHighlighted: isHighlighted(cellDate)
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

// MARK: - Quick Add Sheet
struct QuickAddSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var sheetDetent: PresentationDetent
    @State private var inputText = ""
    @State private var parsedPreview: ParsedEvent?
    @FocusState private var isTextFieldFocused: Bool
    
    let onEventAdded: (Date, String) -> Void
    
    private var isExpanded: Bool {
        sheetDetent == .large
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Expand/Collapse button
            HStack {
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        sheetDetent = isExpanded ? .fraction(0.33) : .large
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(width: 30, height: 30)
                }
                .padding(.trailing, 16)
                .padding(.top, 8)
            }
            
            ScrollView {
                VStack(spacing: 16) {
                    // Parse preview (shown when expanded)
                    if isExpanded, let preview = parsedPreview {
                        ParsePreviewView(event: preview)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .padding(.horizontal, 20)
                    }
                    
                    // Input field
                    TextField("What's coming up next?", text: $inputText)
                        .appFont(size: 17)
                        .padding(16)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(12)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            handleSubmit()
                        }
                        .onChange(of: inputText) { oldValue, newValue in
                            if !newValue.isEmpty {
                                parsedPreview = parseText(newValue)
                            } else {
                                parsedPreview = nil
                            }
                        }
                        .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
            }
        }
        .background(AppTheme.background)
        .interactiveDismissDisabled(false)
        .onAppear {
            isTextFieldFocused = true
        }
    }
    
    private func handleSubmit() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let event = parseText(inputText)
        onEventAdded(event.date, inputText)
        
        inputText = ""
        parsedPreview = nil
        isTextFieldFocused = true
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

// MARK: - Parse Preview View
struct ParsePreviewView: View {
    let event: ParsedEvent
    
    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: event.date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: event.type == .event ? "calendar" : "checkmark.circle")
                    .foregroundColor(AppTheme.accentBlue)
                Text(event.type == .event ? "Calendar Event" : "Task")
                    .appFont(size: 14, weight: .medium)
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Text(event.title)
                .appFont(size: 16, weight: .semibold)
                .foregroundColor(AppTheme.textPrimary)
            
            HStack(spacing: 4) {
                Text(dateString)
                    .appFont(size: 14)
                    .foregroundColor(AppTheme.textSecondary)
                
                if let time = event.time {
                    Text("at \(time)")
                        .appFont(size: 14)
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - #Preview
#Preview {
    ContentView()
}
