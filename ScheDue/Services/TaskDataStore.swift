//
//  TaskDataStore.swift
//  Nota
//
//  Created by GATHREAN DELA CRUZ on 2025-10-24.
//

import Foundation
import Combine

class TaskDataStore: ObservableObject {
    @Published var tasksByDate: [Date: [TaskLine]] = [:]
}
