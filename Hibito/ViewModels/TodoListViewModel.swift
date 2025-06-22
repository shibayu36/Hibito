//
//  TodoListViewModel.swift
//  Hibito
//
//  Created by Yuki Shibazaki on 2025/06/22.
//

import Foundation
import SwiftData

@Observable
@MainActor
class TodoListViewModel {
  private let modelContext: ModelContext
  private(set) var todos: [TodoItem] = []

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
    loadTodos()
  }

  // MARK: - Data Loading

  func loadTodos() {
    let descriptor = FetchDescriptor<TodoItem>(sortBy: [SortDescriptor(\.order)])
    todos = (try? modelContext.fetch(descriptor)) ?? []
  }

  // MARK: - Todo Operations

  func addTodo(content: String) {
    let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedContent.isEmpty else { return }

    let maxOrder = todos.last?.order ?? 0.0
    let newTodo = TodoItem(content: trimmedContent, order: maxOrder + 1.0)
    modelContext.insert(newTodo)

    loadTodos()
  }

  func toggleCompletion(for todo: TodoItem) {
    todo.isCompleted.toggle()
    loadTodos()
  }

  func deleteTodo(at index: Int) {
    guard index >= 0 && index < todos.count else { return }
    modelContext.delete(todos[index])
    loadTodos()
  }

  func moveTodo(from sourceIndex: Int, to destination: Int) {
    guard sourceIndex >= 0 && sourceIndex < todos.count else { return }
    let movingItem = todos[sourceIndex]

    let newOrder = calculateNewOrderValue(
      sourceIndex: sourceIndex,
      destination: destination,
      items: todos
    )

    movingItem.order = newOrder
    loadTodos()
  }

  private func calculateNewOrderValue(
    sourceIndex: Int,
    destination: Int,
    items: [TodoItem]
  ) -> Double {
    guard !items.isEmpty else { return 1.0 }

    let actualDestination = sourceIndex < destination ? destination - 1 : destination

    if actualDestination == 0 {
      return (items.first?.order ?? 0.0) - 1.0
    } else if actualDestination >= items.count - 1 {
      return (items.last?.order ?? 0.0) + 1.0
    } else {
      let prevOrder = items[actualDestination - 1].order
      let nextOrder = items[actualDestination].order
      return (prevOrder + nextOrder) / 2.0
    }
  }

  // MARK: - Reset Functionality

  func performReset() {
    let descriptor = FetchDescriptor<TodoItem>()
    guard let allItems = try? modelContext.fetch(descriptor) else { return }

    // 昨日以前に作成されたタスクを特定
    let tasksToDelete = allItems.filter { item in
      item.createdAt.isBeforeToday()
    }

    // 古いタスクがない場合は何もしない
    guard !tasksToDelete.isEmpty else { return }

    // バッチ削除実行
    for task in tasksToDelete {
      modelContext.delete(task)
    }

    // 変更を保存
    try? modelContext.save()

    loadTodos()
  }
}
