//
//  NaturalLanguageParser.swift
//  Nota
//
//  Created by GATHREAN DELA CRUZ on 2025-10-24.
//

import Foundation
import NaturalLanguage

class NaturalLanguageParser {
    static let shared = NaturalLanguageParser()

    private let calendar = Calendar.current

    // Event indicators
    private let eventKeywords = [
        "dinner", "lunch", "breakfast", "meeting", "appointment", "call",
        "party", "date", "event", "conference", "interview", "class"
    ]

    // Task indicators
    private let taskKeywords = [
        "buy", "finish", "complete", "send", "email", "write", "read",
        "call", "review", "submit", "pay", "book", "schedule", "prepare"
    ]

    private init() {}

    func parse(_ input: String) -> ParsedInput {
        let lowercased = input.lowercased()

        // 1. Detect dates and times
        let (detectedDate, detectedTime) = detectDateTime(in: input)

        // 2. Detect location
        let location = detectLocation(in: input)

        // 3. Classify intent
        let intent = classifyIntent(in: lowercased)

        // 4. Extract title (remove date/time/location references)
        let title = extractTitle(from: input, date: detectedDate, time: detectedTime, location: location)

        // 5. Calculate confidence
        let confidence = calculateConfidence(
            hasDate: detectedDate != nil,
            hasTime: detectedTime != nil,
            hasLocation: location != nil,
            intent: intent
        )

        return ParsedInput(
            originalText: input,
            intent: intent,
            date: detectedDate,
            time: detectedTime,
            location: location,
            title: title,
            confidence: confidence
        )
    }

    // MARK: - Date/Time Detection

    private func detectDateTime(in text: String) -> (date: Date?, time: String?) {
        // First try relative dates
        if let relativeDate = parseRelativeDate(in: text.lowercased()) {
            let time = extractTime(from: text)
            return (relativeDate, time)
        }

        // Then try NSDataDetector for absolute dates
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let matches = detector?.matches(in: text, range: NSRange(text.startIndex..., in: text))

        if let match = matches?.first, let date = match.date {
            let time = extractTime(from: text)
            return (date, time)
        }

        return (nil, nil)
    }

    private func parseRelativeDate(in text: String) -> Date? {
        let today = calendar.startOfDay(for: Date())

        // Today
        if text.contains("today") {
            return today
        }

        // Tomorrow
        if text.contains("tomorrow") {
            return calendar.date(byAdding: .day, value: 1, to: today)
        }

        // Yesterday
        if text.contains("yesterday") {
            return calendar.date(byAdding: .day, value: -1, to: today)
        }

        // Next [weekday]
        if text.contains("next") {
            let weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
            for (index, weekday) in weekdays.enumerated() {
                if text.contains(weekday) {
                    return findNext(weekday: index + 1, from: today) // weekday is 1-indexed (1 = Sunday)
                }
            }
        }

        // This [weekday]
        if text.contains("this") {
            let weekdays = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
            for (index, weekday) in weekdays.enumerated() {
                if text.contains(weekday) {
                    return findThis(weekday: index + 1, from: today)
                }
            }
        }

        return nil
    }

    private func findNext(weekday targetWeekday: Int, from date: Date) -> Date? {
        let currentWeekday = calendar.component(.weekday, from: date)
        var daysToAdd = targetWeekday - currentWeekday

        // If target is today or earlier in week, go to next week
        if daysToAdd <= 0 {
            daysToAdd += 7
        }

        return calendar.date(byAdding: .day, value: daysToAdd, to: date)
    }

    private func findThis(weekday targetWeekday: Int, from date: Date) -> Date? {
        let currentWeekday = calendar.component(.weekday, from: date)
        var daysToAdd = targetWeekday - currentWeekday

        // If target is earlier in week, stay in current week
        if daysToAdd < 0 {
            daysToAdd += 7
        }

        return calendar.date(byAdding: .day, value: daysToAdd, to: date)
    }

    private func extractTime(from text: String) -> String? {
        // Look for time patterns like "at 7", "at 7pm", "at 7:30"
        let timePattern = "(?:at\\s+)?(\\d{1,2})(?::(\\d{2}))?\\s*([ap]m?)?"
        let regex = try? NSRegularExpression(pattern: timePattern, options: .caseInsensitive)

        if let match = regex?.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            var timeString = ""

            // Hour
            if let hourRange = Range(match.range(at: 1), in: text) {
                timeString = String(text[hourRange])
            }

            // Minute
            if let minuteRange = Range(match.range(at: 2), in: text) {
                timeString += ":" + String(text[minuteRange])
            } else {
                timeString += ":00"
            }

            // AM/PM
            if let ampmRange = Range(match.range(at: 3), in: text) {
                timeString += " " + String(text[ampmRange]).uppercased()
            }

            return timeString
        }

        return nil
    }

    // MARK: - Location Detection

    private func detectLocation(in text: String) -> String? {
        // Look for "at [location]" or "in [location]"
        let locationPattern = "(?:at|in)\\s+([A-Z][a-zA-Z\\s]+?)(?:\\s+(?:next|this|tomorrow|today|on)|\\.?$)"
        let regex = try? NSRegularExpression(pattern: locationPattern, options: [])

        if let match = regex?.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
           let locationRange = Range(match.range(at: 1), in: text) {
            return String(text[locationRange]).trimmingCharacters(in: .whitespaces)
        }

        return nil
    }

    // MARK: - Intent Classification

    private func classifyIntent(in text: String) -> ParsedInput.Intent {
        var eventScore = 0
        var taskScore = 0

        // Check for event keywords
        for keyword in eventKeywords {
            if text.contains(keyword) {
                eventScore += 1
            }
        }

        // Check for task keywords
        for keyword in taskKeywords {
            if text.contains(keyword) {
                taskScore += 1
            }
        }

        // Events usually have specific times
        if text.contains("at \\d") || text.contains("pm") || text.contains("am") {
            eventScore += 2
        }

        // Tasks usually have action verbs at the start
        if taskKeywords.contains(where: { text.hasPrefix($0) }) {
            taskScore += 2
        }

        if eventScore > taskScore {
            return .event
        } else if taskScore > eventScore {
            return .task
        } else {
            return .unknown
        }
    }

    // MARK: - Title Extraction

    private func extractTitle(from text: String, date: Date?, time: String?, location: String?) -> String {
        var title = text

        // Remove date-related phrases
        let datePatterns = [
            "next \\w+day", "this \\w+day", "tomorrow", "today", "yesterday",
            "on \\w+day", "\\w+day"
        ]

        for pattern in datePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                title = regex.stringByReplacingMatches(
                    in: title,
                    range: NSRange(title.startIndex..., in: title),
                    withTemplate: ""
                )
            }
        }

        // Remove time phrases
        if let time = time {
            title = title.replacingOccurrences(of: "at \(time)", with: "", options: .caseInsensitive)
        }

        // Remove location phrases
        if let location = location {
            title = title.replacingOccurrences(of: "at \(location)", with: "", options: .caseInsensitive)
            title = title.replacingOccurrences(of: "in \(location)", with: "", options: .caseInsensitive)
        }

        // Clean up extra whitespace
        title = title.trimmingCharacters(in: .whitespaces)
        title = title.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        // Capitalize first letter
        if let first = title.first {
            title = first.uppercased() + title.dropFirst()
        }

        return title.isEmpty ? text : title
    }

    // MARK: - Confidence Calculation

    private func calculateConfidence(hasDate: Bool, hasTime: Bool, hasLocation: Bool, intent: ParsedInput.Intent) -> Double {
        var confidence = 0.0

        if hasDate { confidence += 0.3 }
        if hasTime { confidence += 0.2 }
        if hasLocation { confidence += 0.1 }
        if intent != .unknown { confidence += 0.4 }

        return min(confidence, 1.0)
    }
}
