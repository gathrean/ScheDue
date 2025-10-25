//
//  TaskLineRow.swift
//  Nota
//
//  Created by GATHREAN DELA CRUZ on 2025-10-24.
//

import SwiftUI

struct TaskLineRow: View {
    @Binding var line: TaskLine
    let isFocused: Bool
    let selectedDate: Date
    let onSubmit: () -> Void
    let onFocus: () -> Void
    let onInfoTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggleCompletion: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    private var placeholderText: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            return "What's on your mind?"
        } else if selectedDate < Date() {
            return "Reflecting on this day?"
        } else {
            return "Planning ahead?"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox circle (only show for processed tasks)
            if line.status == .processed {
                Button(action: {
                    onToggleCompletion()
                }) {
                    Image(systemName: line.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22))
                        .foregroundColor(line.isCompleted ? AppTheme.accentBlue : AppTheme.textSecondary)
                }
                .buttonStyle(PlainButtonStyle())
            }

            TextField(placeholderText, text: $line.text)
                .appFont(size: 17)
                .foregroundColor(lineTextColor)
                .strikethrough(line.isCompleted, color: AppTheme.textSecondary)
                .disabled(line.status != .editing)
                .focused($isTextFieldFocused)
                .onSubmit {
                    print("🔑 Return key pressed, text: \(line.text)")
                    onSubmit()
                }
                .submitLabel(.done)
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
            
            HStack(spacing: 4) {
                if line.status == .processing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .transition(.scale.combined(with: .opacity))
                } else if line.status == .processed {
                    // Show parsed data indicators
                    if line.hasScheduledTime {
                        Image(systemName: "clock.fill")
                            .foregroundColor(AppTheme.accentBlue)
                            .font(.caption)
                    }
                    if line.hasLocation {
                        Image(systemName: "location.fill")
                            .foregroundColor(AppTheme.accentBlue)
                            .font(.caption)
                    }
                    if line.isEvent {
                        Image(systemName: "calendar")
                            .foregroundColor(AppTheme.accentBlue)
                            .font(.caption)
                    }

                    Button(action: onInfoTap) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(AppTheme.accentBlue)
                            .font(.title3)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(minWidth: 30)
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
        if line.isCompleted {
            return AppTheme.textSecondary.opacity(0.6)
        }

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
