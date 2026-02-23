//
//  TodoListViewModelTests.swift
//  HibitoTests
//
//  Created by Yuki Shibazaki on 2025/06/22.
//

import Foundation
import SwiftData
import Testing

@testable import Hibito

@MainActor
struct TodoListViewModelTests {

  /// テスト用のin-memoryModelContextを作成します
  /// - Returns: 作成されたModelContext
  private func createTestContainer() throws -> ModelContainer {
    let schema = Schema([TodoItem.self, Settings.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [config])
    return container
  }

  @Test
  func Todo追加から完了切り替えと削除までの基本操作() async throws {
    let container = try createTestContainer()
    let modelContext = container.mainContext
    let settingsRepository = SettingsRepository(modelContext: modelContext)
    let viewModel = TodoListViewModel(
      modelContext: modelContext, settingsRepository: settingsRepository)

    // 初期状態: Todoリストが空
    #expect(viewModel.todos.isEmpty)

    // 1つ目のTodo追加
    viewModel.addTodo(content: "タスク1")
    #expect(viewModel.todos.count == 1)
    #expect(viewModel.todos[0].content == "タスク1")
    #expect(viewModel.todos[0].order > 0.0)  // timeIntervalSince1970ベースで正の値
    #expect(viewModel.todos[0].isCompleted == false)

    // 2つ目のTodo追加
    let firstOrder = viewModel.todos[0].order
    viewModel.addTodo(content: "タスク2")
    #expect(viewModel.todos.count == 2)
    #expect(viewModel.todos[1].content == "タスク2")
    #expect(viewModel.todos[1].order > firstOrder)  // 2つ目の方が大きい値
    #expect(viewModel.todos[1].isCompleted == false)

    // 2つ目のTodoを完了状態に変更
    let secondTodo = viewModel.todos[1]
    viewModel.toggleCompletion(for: secondTodo)
    #expect(viewModel.todos[1].isCompleted == true)

    // 2つ目のTodoを未完了に戻す
    viewModel.toggleCompletion(for: secondTodo)
    #expect(viewModel.todos[1].isCompleted == false)

    // 1つ目のTodoを削除
    viewModel.deleteTodo(at: 0)
    #expect(viewModel.todos.count == 1)
    #expect(viewModel.todos[0].content == "タスク2")
  }

  @Test
  func 空文字やスペースのみのTodoは追加されない() async throws {
    let container = try createTestContainer()
    let modelContext = container.mainContext
    let settingsRepository = SettingsRepository(modelContext: modelContext)
    let viewModel = TodoListViewModel(
      modelContext: modelContext, settingsRepository: settingsRepository)

    // 空文字を追加
    viewModel.addTodo(content: "")
    #expect(viewModel.todos.isEmpty)

    // スペースのみを追加
    viewModel.addTodo(content: "   ")
    #expect(viewModel.todos.isEmpty)

    // 改行とスペースのみを追加
    viewModel.addTodo(content: " \n  ")
    #expect(viewModel.todos.isEmpty)

    // 正常なテキストを追加
    viewModel.addTodo(content: "  有効なタスク  ")
    #expect(viewModel.todos.count == 1)
    #expect(viewModel.todos[0].content == "有効なタスク")
  }

  @Test
  func Todo追加時に中間の改行がスペースに置換される() async throws {
    let container = try createTestContainer()
    let modelContext = container.mainContext
    let settingsRepository = SettingsRepository(modelContext: modelContext)
    let viewModel = TodoListViewModel(
      modelContext: modelContext, settingsRepository: settingsRepository)

    // 中間に改行を含むテキスト（音声入力で発生するケース）
    viewModel.addTodo(content: "タスク1の\n続きの内容\n")
    #expect(viewModel.todos.count == 1)
    #expect(viewModel.todos[0].content == "タスク1の続きの内容")
  }

  @Test
  func Todoの並び替えが正しく動作する() async throws {
    let container = try createTestContainer()
    let modelContext = container.mainContext
    let settingsRepository = SettingsRepository(modelContext: modelContext)
    let viewModel = TodoListViewModel(
      modelContext: modelContext, settingsRepository: settingsRepository)

    // 4つのTodoを追加
    viewModel.addTodo(content: "タスク1")
    viewModel.addTodo(content: "タスク2")
    viewModel.addTodo(content: "タスク3")
    viewModel.addTodo(content: "タスク4")

    // ケース1: タスク3を上（2番目）に移動
    viewModel.moveTodo(from: 2, to: 1)
    #expect(viewModel.todos[0].content == "タスク1")
    #expect(viewModel.todos[1].content == "タスク3")
    #expect(viewModel.todos[2].content == "タスク2")
    #expect(viewModel.todos[3].content == "タスク4")

    // ケース2: タスク1を下（3番目）に移動
    viewModel.moveTodo(from: 0, to: 3)
    #expect(viewModel.todos[0].content == "タスク3")
    #expect(viewModel.todos[1].content == "タスク2")
    #expect(viewModel.todos[2].content == "タスク1")
    #expect(viewModel.todos[3].content == "タスク4")

    // ケース3: タスク4を先頭に移動
    viewModel.moveTodo(from: 3, to: 0)
    #expect(viewModel.todos[0].content == "タスク4")
    #expect(viewModel.todos[1].content == "タスク3")
    #expect(viewModel.todos[2].content == "タスク2")
    #expect(viewModel.todos[3].content == "タスク1")

    // ケース4: タスク4を末尾に移動
    viewModel.moveTodo(from: 0, to: 4)
    #expect(viewModel.todos[0].content == "タスク3")
    #expect(viewModel.todos[1].content == "タスク2")
    #expect(viewModel.todos[2].content == "タスク1")
    #expect(viewModel.todos[3].content == "タスク4")
  }

  @Test
  func 昨日作成されたTodoはすべて削除される() async throws {
    let container = try createTestContainer()
    let context = container.mainContext
    let settingsRepository = SettingsRepository(modelContext: context)
    let viewModel = TodoListViewModel(modelContext: context, settingsRepository: settingsRepository)

    // 昨日のTodoを3つ作成
    let yesterdayTodo1 = TodoItem(content: "昨日のタスク1", order: 1.0)
    yesterdayTodo1.createdAt = Date().addingTimeInterval(-24 * 60 * 60)  // 24時間前
    context.insert(yesterdayTodo1)

    let yesterdayTodo2 = TodoItem(content: "昨日のタスク2", order: 2.0)
    yesterdayTodo2.createdAt = Date().addingTimeInterval(-24 * 60 * 60)
    context.insert(yesterdayTodo2)

    let yesterdayTodo3 = TodoItem(content: "昨日のタスク3", order: 3.0)
    yesterdayTodo3.createdAt = Date().addingTimeInterval(-24 * 60 * 60)
    context.insert(yesterdayTodo3)

    // リロードして確認
    viewModel.loadTodos()
    #expect(viewModel.todos.count == 3)

    // リセットを実行
    viewModel.performReset()

    // すべてのタスクが削除されたことを確認
    #expect(viewModel.todos.isEmpty)
  }

  @Test
  func 今日作成されたTodoはすべて残る() async throws {
    let container = try createTestContainer()
    let context = container.mainContext
    let settingsRepository = SettingsRepository(modelContext: context)
    let viewModel = TodoListViewModel(modelContext: context, settingsRepository: settingsRepository)

    // 今日のTodoを3つ作成
    viewModel.addTodo(content: "今日のタスク1")
    viewModel.addTodo(content: "今日のタスク2")
    viewModel.addTodo(content: "今日のタスク3")

    // リセットを実行
    viewModel.performReset()

    // すべてのタスクが残っていることを確認
    #expect(viewModel.todos.count == 3)
    #expect(viewModel.todos[0].content == "今日のタスク1")
    #expect(viewModel.todos[1].content == "今日のタスク2")
    #expect(viewModel.todos[2].content == "今日のタスク3")
  }

  @Test
  func 設定したリセット時刻を超えるとその前に作成されたTodoはすべて削除される() async throws {
    let container = try createTestContainer()
    let context = container.mainContext
    let settingsRepository = SettingsRepository(modelContext: context)

    // リセット時刻を9時に設定
    settingsRepository.updateResetTime(9)

    let viewModel = TodoListViewModel(
      modelContext: context,
      settingsRepository: settingsRepository
    )

    // 基準時刻（今日の8:30）
    let baseDate = Calendar.current.date(bySettingHour: 8, minute: 30, second: 0, of: Date())!

    // 前日の22:00に作成されたTodo（削除対象になる予定）
    let yesterdayTodo = TodoItem(content: "前日22時のタスク", order: 1.0)
    yesterdayTodo.createdAt = Calendar.current.date(
      byAdding: .day, value: -1,
      to: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: baseDate)!)!
    context.insert(yesterdayTodo)

    // 当日の8:00に作成されたTodo（削除対象になる予定）
    let todayTodo = TodoItem(content: "当日8時のタスク", order: 2.0)
    todayTodo.createdAt = Calendar.current.date(
      bySettingHour: 8, minute: 0, second: 0, of: baseDate)!
    context.insert(todayTodo)

    viewModel.loadTodos()
    #expect(viewModel.todos.count == 2)

    // 8:30にperformReset（リセット時刻前なので削除されない）
    viewModel.performReset(date: baseDate)
    #expect(viewModel.todos.count == 2)

    // 時刻を9:30に変更（リセット時刻を超えた）
    let afterResetDate = Calendar.current.date(
      bySettingHour: 9, minute: 30, second: 0, of: baseDate)!

    // 9:30にperformReset（リセット時刻を超えたので削除される）
    viewModel.performReset(date: afterResetDate)
    #expect(viewModel.todos.count == 0)
  }

  @Test
  func calculateOrderValue_先頭に移動() async throws {
    let container = try createTestContainer()
    let context = container.mainContext
    let settingsRepository = SettingsRepository(modelContext: context)
    let viewModel = TodoListViewModel(modelContext: context, settingsRepository: settingsRepository)

    let items = [
      TodoItem(content: "タスク1", order: 1.0),
      TodoItem(content: "タスク2", order: 2.0),
      TodoItem(content: "タスク3", order: 3.0),
    ]

    // 先頭（インデックス0）に移動
    let result = viewModel.calculateOrderValue(destination: 0, items: items)
    #expect(result == 0.0)  // 1.0 - 1.0
  }

  @Test
  func calculateOrderValue_末尾に移動() async throws {
    let container = try createTestContainer()
    let context = container.mainContext
    let settingsRepository = SettingsRepository(modelContext: context)
    let viewModel = TodoListViewModel(modelContext: context, settingsRepository: settingsRepository)

    let items = [
      TodoItem(content: "タスク1", order: 1.0),
      TodoItem(content: "タスク2", order: 2.0),
      TodoItem(content: "タスク3", order: 3.0),
    ]

    // 末尾（インデックス3以上）に移動
    let result = viewModel.calculateOrderValue(destination: 3, items: items)
    #expect(result == 4.0)  // 3.0 + 1.0
  }

  @Test
  func calculateOrderValue_中間位置に移動() async throws {
    let container = try createTestContainer()
    let context = container.mainContext
    let settingsRepository = SettingsRepository(modelContext: context)
    let viewModel = TodoListViewModel(modelContext: context, settingsRepository: settingsRepository)

    let items = [
      TodoItem(content: "タスク1", order: 1.0),
      TodoItem(content: "タスク2", order: 2.0),
      TodoItem(content: "タスク3", order: 3.0),
      TodoItem(content: "タスク4", order: 4.0),
    ]

    // インデックス1に移動
    let result = viewModel.calculateOrderValue(destination: 1, items: items)
    #expect(result == 1.5)  // (1.0 + 2.0) / 2.0
  }

  @Test
  func getLastResetTime_0時に指定されていた時() async throws {
    let container = try createTestContainer()
    let context = container.mainContext
    let settingsRepository = SettingsRepository(modelContext: context)
    let viewModel = TodoListViewModel(modelContext: context, settingsRepository: settingsRepository)

    // リセット時刻を0時に設定
    settingsRepository.updateResetTime(0)

    let todayMidnight = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!

    // 必ず当日の0時を返す
    let now = Date()

    // 1時
    let lastResetTime1 = viewModel.getLastResetTime(
      now: Calendar.current.date(bySettingHour: 1, minute: 0, second: 0, of: now)!)
    #expect(lastResetTime1 == todayMidnight)

    // 12時
    let lastResetTime12 = viewModel.getLastResetTime(
      now: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: now)!)
    #expect(lastResetTime12 == todayMidnight)

    // 23時
    let lastResetTime23 = viewModel.getLastResetTime(
      now: Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: now)!)
    #expect(lastResetTime23 == todayMidnight)
  }

  @Test
  func getLastResetTime_12時に指定されていた時() async throws {
    let container = try createTestContainer()
    let context = container.mainContext
    let settingsRepository = SettingsRepository(modelContext: context)
    let viewModel = TodoListViewModel(modelContext: context, settingsRepository: settingsRepository)

    // リセット時刻を12時に設定
    settingsRepository.updateResetTime(12)

    let now = Date()

    // 当日の11時なら前日の12時を返す
    let todayNoon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: now)!
    let yesterdayNoon = Calendar.current.date(byAdding: .day, value: -1, to: todayNoon)!
    let lastResetTime11 = viewModel.getLastResetTime(
      now: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: now)!)
    #expect(lastResetTime11 == yesterdayNoon)

    // 当日の13時なら当日の12時を返す
    let lastResetTime13 = viewModel.getLastResetTime(
      now: Calendar.current.date(bySettingHour: 13, minute: 0, second: 0, of: now)!)
    #expect(lastResetTime13 == todayNoon)
  }
}
