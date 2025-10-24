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
