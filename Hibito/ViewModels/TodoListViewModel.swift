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

  /// SwiftDataからTodoアイテムを読み込んでtodos配列を更新します
  /// order値でソートされた状態で取得されます
  func loadTodos() {
    let descriptor = FetchDescriptor<TodoItem>(sortBy: [SortDescriptor(\.order)])
    todos = (try? modelContext.fetch(descriptor)) ?? []
    for (_, todo) in todos.enumerated() {
      print("content: \(todo.content), order: \(todo.order)")
    }
  }

  /// 新しいTodoアイテムを追加します
  /// - Parameter content: 追加するTodoの内容（前後の空白は自動的に削除されます）
  /// - Note: 空文字またはスペースのみの場合は追加されません
  func addTodo(content: String) {
    let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedContent.isEmpty else { return }

    let maxOrder = todos.last?.order ?? 0.0
    let newTodo = TodoItem(content: trimmedContent, order: maxOrder + 1.0)
    modelContext.insert(newTodo)

    loadTodos()
  }

  /// 指定されたTodoアイテムの完了状態を切り替えます
  /// - Parameter todo: 完了状態を切り替えるTodoアイテム
  func toggleCompletion(for todo: TodoItem) {
    todo.isCompleted.toggle()
    loadTodos()
  }

  /// 指定されたインデックスのTodoアイテムを削除します
  /// - Parameter index: 削除するTodoアイテムのインデックス
  /// - Note: インデックスが範囲外の場合は何も実行されません
  func deleteTodo(at index: Int) {
    guard index >= 0 && index < todos.count else { return }
    modelContext.delete(todos[index])
    loadTodos()
  }

  /// Todoアイテムを別の位置に移動します
  /// sourceIndexやdestinationはSwiftUIのonMoveから提供される値を前提とする
  /// - Parameters:
  ///   - sourceIndex: 移動元のインデックス
  ///   - destination: 移動先のインデックス
  /// - Note: ソースインデックスが範囲外の場合は何も実行されません
  func moveTodo(from sourceIndex: Int, to destination: Int) {
    guard sourceIndex >= 0 && sourceIndex < todos.count else { return }
    let movingItem = todos[sourceIndex]

    let newOrder = calculateOrderValue(
      destination: destination,
      items: todos
    )

    movingItem.order = newOrder
    loadTodos()
  }

  /// 指定したインデックスに挿入する場合のorder値を計算する
  /// - Parameters:
  ///   - destination: 実際の挿入位置のインデックス
  ///   - items: 現在のアイテム配列
  /// - Returns: order値
  /// - Note: 先頭に移動する場合は最小order値-1.0、末尾の場合は最大order値+1.0、
  ///         中間位置の場合は前後のorder値の平均値を返します
  internal func calculateOrderValue(
    destination: Int,
    items: [TodoItem]
  ) -> Double {
    guard !items.isEmpty else { return 1.0 }

    if destination == 0 {
      // 先頭に追加
      return (items.first?.order ?? 0.0) - 1.0
    } else if destination >= items.count {
      // 末尾に追加
      return (items.last?.order ?? 0.0) + 1.0
    } else {
      // 中間に追加
      let prevOrder = items[destination - 1].order
      let nextOrder = items[destination].order
      return (prevOrder + nextOrder) / 2.0
    }
  }

  /// 昨日以前に作成されたTodoアイテムを削除します（日次リセット機能）
  /// - Note: 今日作成されたアイテムは削除されません
  /// - Note: 削除対象がない場合は何も実行されません
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
