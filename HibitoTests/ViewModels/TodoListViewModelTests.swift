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

struct TodoListViewModelTests {

  /// テスト用のin-memoryModelContextを作成します
  /// - Returns: 作成されたModelContext
  @MainActor
  private func createTestContainer() throws -> ModelContainer {
    let schema = Schema([TodoItem.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: schema, configurations: [config])
    return container
  }

  @MainActor
  @Test
  func Todo追加から完了切り替えと削除までの基本操作() async throws {
    let container = try createTestContainer()
    let viewModel = TodoListViewModel(modelContext: container.mainContext)

    // 初期状態: Todoリストが空
    #expect(viewModel.todos.isEmpty)

    // 1つ目のTodo追加
    viewModel.addTodo(content: "タスク1")
    #expect(viewModel.todos.count == 1)
    #expect(viewModel.todos[0].content == "タスク1")
    #expect(viewModel.todos[0].order == 1.0)
    #expect(viewModel.todos[0].isCompleted == false)

    // 2つ目のTodo追加
    viewModel.addTodo(content: "タスク2")
    #expect(viewModel.todos.count == 2)
    #expect(viewModel.todos[1].content == "タスク2")
    #expect(viewModel.todos[1].order == 2.0)
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

  @MainActor
  @Test
  func 空文字やスペースのみのTodoは追加されない() async throws {
    let container = try createTestContainer()
    let viewModel = TodoListViewModel(modelContext: container.mainContext)

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

  @MainActor
  @Test
  func Todoの並び替えが正しく動作する() async throws {
    let container = try createTestContainer()
    let viewModel = TodoListViewModel(modelContext: container.mainContext)

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

  @MainActor
  @Test
  func 昨日作成されたTodoはすべて削除される() async throws {
    let container = try createTestContainer()
    let context = container.mainContext
    let viewModel = TodoListViewModel(modelContext: context)

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

  @MainActor
  @Test
  func 今日作成されたTodoはすべて残る() async throws {
    let container = try createTestContainer()
    let context = container.mainContext
    let viewModel = TodoListViewModel(modelContext: context)

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

  @MainActor
  @Test
  func calculateNewOrderValue_先頭に移動() async throws {
    let container = try createTestContainer()
    let context = container.mainContext
    let viewModel = TodoListViewModel(modelContext: context)

    let items = [
      TodoItem(content: "タスク1", order: 1.0),
      TodoItem(content: "タスク2", order: 2.0),
      TodoItem(content: "タスク3", order: 3.0),
    ]

    // 先頭（インデックス0）に移動
    let result = viewModel.calculateNewOrderValue(destination: 0, items: items)
    #expect(result == 0.0)  // 1.0 - 1.0
  }

  @MainActor
  @Test
  func calculateNewOrderValue_末尾に移動() async throws {
    let container = try createTestContainer()
    let context = container.mainContext
    let viewModel = TodoListViewModel(modelContext: context)

    let items = [
      TodoItem(content: "タスク1", order: 1.0),
      TodoItem(content: "タスク2", order: 2.0),
      TodoItem(content: "タスク3", order: 3.0),
    ]

    // 末尾（インデックス3以上）に移動
    let result = viewModel.calculateNewOrderValue(destination: 3, items: items)
    #expect(result == 4.0)  // 3.0 + 1.0
  }

  @MainActor
  @Test
  func calculateNewOrderValue_中間位置に移動() async throws {
    let container = try createTestContainer()
    let context = container.mainContext
    let viewModel = TodoListViewModel(modelContext: context)

    let items = [
      TodoItem(content: "タスク1", order: 1.0),
      TodoItem(content: "タスク2", order: 2.0),
      TodoItem(content: "タスク3", order: 3.0),
      TodoItem(content: "タスク4", order: 4.0),
    ]

    // インデックス1に移動
    let result = viewModel.calculateNewOrderValue(destination: 1, items: items)
    #expect(result == 1.5)  // (1.0 + 2.0) / 2.0
  }

}
