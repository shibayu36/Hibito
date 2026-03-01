//
//  TodoListViewModel.swift
//  Hibito
//
//  Created by Yuki Shibazaki on 2025/06/22.
//

import Combine
import CoreData
import Foundation
import SwiftData

@Observable
@MainActor
class TodoListViewModel {
  private let modelContext: ModelContext
  private let settingsRepository: SettingsRepository
  private(set) var todos: [TodoItem] = []
  private var cancellables: Set<AnyCancellable> = []
  // iCloudでデータをimportした時刻を保持する。Listの更新をトリガーにするために使用する。
  private(set) var iCloudImportDate: Date

  init(modelContext: ModelContext, settingsRepository: SettingsRepository) {
    self.modelContext = modelContext
    self.settingsRepository = settingsRepository
    self.iCloudImportDate = Date()
    loadTodos()
    setupCloudKitNotificationObserver()
  }

  /// CloudKitでデータをimportした時に、todos配列を更新する
  private func setupCloudKitNotificationObserver() {
    NotificationCenter.default
      .publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
      .compactMap { notification -> NSPersistentCloudKitContainer.Event? in
        notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
          as? NSPersistentCloudKitContainer.Event
      }
      .filter { event in
        event.type == .import && event.succeeded
      }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.loadTodos()
        self?.iCloudImportDate = Date()
      }
      .store(in: &cancellables)
  }

  /// SwiftDataからTodoアイテムを読み込んでtodos配列を更新します
  /// 完了アイテムを上部、未完了アイテムを下部に配置し、各グループ内はorder値でソートされます
  func loadTodos() {
    let descriptor = FetchDescriptor<TodoItem>(sortBy: [
      SortDescriptor(\.order),
      // 最悪orderが一致した時に安定させる
      SortDescriptor(\.id),
    ])
    let allTodos = (try? modelContext.fetch(descriptor)) ?? []
    let completed = allTodos.filter { $0.isCompleted }
    let uncompleted = allTodos.filter { !$0.isCompleted }
    todos = completed + uncompleted
  }

  /// 新しいTodoアイテムを追加します
  /// - Parameter content: 追加するTodoの内容（改行文字は除去され、前後の空白は自動的に削除されます）
  /// - Note: 空文字またはスペースのみの場合は追加されません
  func addTodo(content: String) {
    let sanitizedContent = content.components(separatedBy: .newlines).joined()
    let trimmedContent = sanitizedContent.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedContent.isEmpty else { return }

    let newOrder = TodoItem.generateNewOrder()
    let newTodo = TodoItem(content: trimmedContent, order: newOrder)
    modelContext.insert(newTodo)
    try? modelContext.save()

    loadTodos()
  }

  /// 指定されたTodoアイテムの完了状態を切り替え、グループ内の適切な位置にorder値を調整します
  /// - Parameter todo: 完了状態を切り替えるTodoアイテム
  /// - Note: Done時は完了グループの末尾、Done解除時は未完了グループの先頭に配置されます
  func toggleCompletion(for todo: TodoItem) {
    let becomingCompleted = !todo.isCompleted

    if becomingCompleted {
      // 完了グループの末尾に配置
      let lastCompletedOrder = todos.last(where: { $0.isCompleted })?.order
      todo.order = (lastCompletedOrder ?? 0) + 1
    } else {
      // 未完了グループの先頭に配置
      let firstUncompletedOrder = todos.first(where: { !$0.isCompleted })?.order
      todo.order = (firstUncompletedOrder ?? 0) - 1
    }

    todo.isCompleted.toggle()
    try? modelContext.save()
    loadTodos()
  }

  /// 指定されたインデックスのTodoアイテムを削除します
  /// - Parameter index: 削除するTodoアイテムのインデックス
  /// - Note: インデックスが範囲外の場合は何も実行されません
  func deleteTodo(at index: Int) {
    guard index >= 0 && index < todos.count else { return }
    modelContext.delete(todos[index])
    try? modelContext.save()
    loadTodos()
  }

  /// 未完了のTodoアイテムを別の位置に移動します
  /// sourceIndexやdestinationはSwiftUIのonMoveから提供される値を前提とする
  /// - Parameters:
  ///   - sourceIndex: 移動元のインデックス
  ///   - destination: 移動先のインデックス
  /// - Note: 完了アイテムの移動は無視されます。移動先は未完了アイテム範囲に制限されます。
  func moveTodo(from sourceIndex: Int, to destination: Int) {
    guard sourceIndex >= 0 && sourceIndex < todos.count else { return }
    let movingItem = todos[sourceIndex]
    guard !movingItem.isCompleted else { return }

    // onMoveのdestinationはtodos全体のインデックスなので、
    // 先頭の完了アイテム数を引いて未完了配列のインデックスに変換し、範囲内に収める
    let uncompletedItems = todos.filter { !$0.isCompleted }
    let completedCount = todos.count - uncompletedItems.count
    let adjustedDestination = min(
      max(destination - completedCount, 0), uncompletedItems.count)

    let newOrder = calculateOrderValue(
      destination: adjustedDestination,
      items: uncompletedItems
    )

    movingItem.order = newOrder
    try? modelContext.save()
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

  /// 最後のリセット時刻を取得します
  /// 現在時刻がリセット時刻より前の場合は昨日のリセット時刻、
  /// リセット時刻以降の場合は今日のリセット時刻を返します
  internal func getLastResetTime(now: Date) -> Date {
    let calendar = Calendar.current
    let resetHour = settingsRepository.getResetTime()

    // 今日の指定時刻を作成
    guard
      let todayResetTime = calendar.date(bySettingHour: resetHour, minute: 0, second: 0, of: now)
    else {
      return now
    }

    // 現在時刻がリセット時刻より前なら昨日のリセット時刻
    if now < todayResetTime {
      return calendar.date(byAdding: .day, value: -1, to: todayResetTime) ?? todayResetTime
    }

    // リセット時刻以降なら今日のリセット時刻
    return todayResetTime
  }

  /// 設定された時間より前に作成されたTodoアイテムを削除します（日次リセット機能）
  /// - Parameter date: 基準となる現在時刻（デフォルトは現在時刻）
  /// - Note: 最後のリセット時刻より後に作成されたアイテムは削除されません
  /// - Note: 削除対象がない場合は何も実行されません
  func performReset(date: Date = Date()) {
    let descriptor = FetchDescriptor<TodoItem>()
    guard let allItems = try? modelContext.fetch(descriptor) else { return }

    // 最後のリセット時刻を取得
    let lastResetTime = getLastResetTime(now: date)

    // 最後のリセット時刻より前に作成されたタスクを特定
    let tasksToDelete = allItems.filter { item in
      item.createdAt < lastResetTime
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
