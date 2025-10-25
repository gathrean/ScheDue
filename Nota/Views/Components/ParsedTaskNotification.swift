//
//  ParsedTaskNotification.swift
//  Nota
//
//  Created by GATHREAN DELA CRUZ on 2025-10-24.
//

import SwiftUI

struct ParsedTaskNotification: View {
    let parsed: ParsedInput
    let targetDate: Date
    let onJump: () -> Void
    let onDismiss: () -> Void

    @State private var showDetails = false

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: iconName)
                            .foregroundColor(.white)
                            .font(.caption)

                        Text(notificationTitle)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text(dateFormatter.string(from: targetDate))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.9))

                    if showDetails {
                        VStack(alignment: .leading, spacing: 2) {
                            if let time = parsed.time {
                                DetailRow(icon: "clock.fill", text: time)
                            }
                            if let location = parsed.location {
                                DetailRow(icon: "location.fill", text: location)
                            }
                            DetailRow(icon: "gauge", text: "Confidence: \(Int(parsed.confidence * 100))%")
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }

                Spacer()

                VStack(spacing: 8) {
                    Button(action: onJump) {
                        Text("Jump")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.accentBlue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .cornerRadius(6)
                    }

                    Button(action: {
                        withAnimation {
                            showDetails.toggle()
                        }
                    }) {
                        Image(systemName: showDetails ? "chevron.up.circle.fill" : "info.circle.fill")
                            .foregroundColor(.white.opacity(0.9))
                            .font(.system(size: 20))
                    }
                }
            }
        }
        .padding(16)
        .background(backgroundColor)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 20)
    }

    private var iconName: String {
        switch parsed.intent {
        case .event:
            return "calendar"
        case .task:
            return "checkmark.circle"
        case .note:
            return "note.text"
        case .unknown:
            return "questionmark.circle"
        }
    }

    private var notificationTitle: String {
        switch parsed.intent {
        case .event:
            return "Event added"
        case .task:
            return "Task added"
        case .note:
            return "Note added"
        case .unknown:
            return "Added"
        }
    }

    private var backgroundColor: Color {
        switch parsed.intent {
        case .event:
            return Color.purple
        case .task:
            return AppTheme.accentBlue
        case .note:
            return Color.orange
        case .unknown:
            return Color.gray
        }
    }
}

struct DetailRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.8))
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}
