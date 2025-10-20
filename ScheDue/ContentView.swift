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

// MARK: - Content View
struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Add", systemImage: "plus.circle.fill")
                }
                .tag(0)
            
            CalendarView()
                .tabItem {
                    Label("Sched", systemImage: "calendar")
                }
                .tag(1)
            
            DueView()
                .tabItem {
                    Label("Due", systemImage: "checklist")
                }
                .tag(2)
        }
    }
}

// MARK: - Home View
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
                                .background(AppTheme.background)
                            }
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .principal) {
                                    Text("ScheDue")
                                        .font(AppTheme.headerFont(size: 28))
                                }
                            }
                            .background(AppTheme.background)
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
        
        func handleBackspaceOnEmpty(_ line: TaskLine) {
            if let currentIndex = lines.firstIndex(where: { $0.id == line.id }),
               currentIndex > 0 {
                let previousLine = lines[currentIndex - 1]
                
                if previousLine.status == .processed {
                    handleEdit(previousLine)
                } else {
                    focusedLineId = previousLine.id
                }
            }
        }
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
    let onBackspaceOnEmpty: () -> Void
    
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

// MARK: - Calendar View
struct CalendarView: View {
    @State private var currentVisibleMonth = Date()
    @State private var hasScrolledToToday = false
    
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
                                        isFullyVisible: calendar.isDate(currentVisibleMonth, equalTo: monthDate, toGranularity: .month)
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
                        // Only scroll once on first appear
                        if !hasScrolledToToday {
                            proxy.scrollTo(todayMonthIndex, anchor: .top)
                            hasScrolledToToday = true
                            currentVisibleMonth = Date()
                        }
                    }
                    .overlay(alignment: .bottom) {
                        if !isViewingCurrentMonth {
                            Button(action: {
                                scrollToToday(proxy: proxy)
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "calendar.circle.fill")
                                        .font(.body)
                                    Text("Today")
                                        .appFont(size: 16, weight: .semibold)
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
                            .padding(.bottom, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
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
        withAnimation(.easeInOut(duration: 0.5)) {
            proxy.scrollTo(todayMonthIndex, anchor: .top)
        }
    }
}

// MARK: - Month View
struct MonthView: View {
    let date: Date
    let isFullyVisible: Bool
    
    private let calendar = Calendar.current
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(calendarDays, id: \.self) { cellDate in
                if let cellDate = cellDate {
                    DayCell(
                        date: cellDate,
                        isToday: isToday(cellDate),
                        isCurrentMonth: isCurrentMonth(cellDate),
                        isFullyVisible: isFullyVisible
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
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let isToday: Bool
    let isCurrentMonth: Bool
    let isFullyVisible: Bool
    
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
                // TODO: Show event dots or list here
            }
            .frame(minHeight: 20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: AppTheme.dayCellHeight)
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

// MARK: - Due View
struct DueView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Divider()
                
                ScrollView {
                    VStack(spacing: 16) {
                        Text("Due List View")
                            .appFont(size: 22, weight: .semibold)
                            .foregroundColor(AppTheme.textSecondary)
                            .padding(.top, 40)
                        
                        Text("Tasks and events will appear here in list format")
                            .appFont(size: 17)
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
                .background(AppTheme.background)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Due")
                        .font(AppTheme.headerFont(size: 28))
                }
            }
            .background(AppTheme.background)
        }
    }
}

// MARK: - #Preview
#Preview {
    ContentView()
}
