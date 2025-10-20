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
    case completed      // Successfully processed
}

struct ContentView: View {
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
                                }
                            )
                        }
                    }
                }
                
                // Processing cards area with glassmorphism
                ProcessingCardsView(lines: lines.filter { $0.status == .processing || $0.status == .completed })
            }
            .navigationTitle("ScheDue")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Focus first line on launch
                if let firstLine = lines.first {
                    focusedLineId = firstLine.id
                }
            }
        }
    }
    
    func handleLineSubmit(_ line: TaskLine) {
        guard !line.text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        // Find and update the line status
        if let index = lines.firstIndex(where: { $0.id == line.id }) {
            lines[index].status = .processing
            
            // Simulate processing
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if let idx = lines.firstIndex(where: { $0.id == line.id }) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        lines[idx].status = .completed
                    }
                }
            }
            
            // Add new empty line and focus it
            let newLine = TaskLine(text: "")
            lines.append(newLine)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                focusedLineId = newLine.id
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
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkmark for completed items
            if line.status == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                    .transition(.scale.combined(with: .opacity))
            }
            
            TextField("What's coming up next?", text: $line.text)
                .font(.body)
                .foregroundColor(line.status == .editing ? .primary : .secondary)
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
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .onChange(of: isFocused) { _, newValue in
            isTextFieldFocused = newValue
        }
    }
}

// Glassmorphism processing cards
struct ProcessingCardsView: View {
    let lines: [TaskLine]
    
    var body: some View {
        if !lines.isEmpty {
            VStack(spacing: 0) {
                Divider()
                
                ZStack {
                    // Glassmorphism background
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea(edges: .bottom)
                    
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(lines) { line in
                                ProcessingCard(line: line)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal: .opacity
                                    ))
                            }
                        }
                        .padding()
                    }
                    .frame(maxHeight: 250)
                }
                .frame(maxHeight: 250)
            }
        }
    }
}

// Individual processing card with slide-up animation
struct ProcessingCard: View {
    let line: TaskLine
    
    var body: some View {
        HStack(spacing: 12) {
            Text(line.text)
                .foregroundColor(.secondary)
                .font(.body)
                .lineLimit(2)
            
            Spacer()
            
            if line.status == .processing {
                ProgressView()
                    .scaleEffect(0.8)
            } else if line.status == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    ContentView()
}
