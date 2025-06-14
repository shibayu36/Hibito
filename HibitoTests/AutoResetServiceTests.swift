import Foundation
import SwiftData
import Testing

@testable import Hibito

struct AutoResetServiceTests {

  // MARK: - Setup Helper

  /// テスト用のSwiftDataコンテキストを作成
  @MainActor private func createTestContext() -> ModelContext {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TodoItem.self, configurations: config)
    return ModelContext(container)
  }

  // MARK: - リセット機能のテスト

  @Test("今日のタスクのみの場合はリセットしない")
  @MainActor func testCheckAndPerformResetWithTodayTasksOnly() {
    let context = createTestContext()

    // 今日のタスクを作成
    let todayTask = TodoItem(content: "今日のタスク")
    todayTask.createdAt = Date()
    context.insert(todayTask)

    // リセットチェック実行
    let didReset = AutoResetService.checkAndPerformReset(context: context)

    #expect(didReset == false)

    // タスクが残っていることを確認
    let descriptor = FetchDescriptor<TodoItem>()
    let remainingTasks = try! context.fetch(descriptor)
    #expect(remainingTasks.count == 1)
    #expect(remainingTasks.first?.content == "今日のタスク")
  }

  @Test("昨日のタスクがあればリセットを実行")
  @MainActor func testCheckAndPerformResetWithYesterdayTasks() {
    let context = createTestContext()

    // 昨日のタスクを作成
    let calendar = Calendar.current
    let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
    let yesterdayTask = TodoItem(content: "昨日のタスク")
    yesterdayTask.createdAt = yesterday
    context.insert(yesterdayTask)

    // リセットチェック実行
    let didReset = AutoResetService.checkAndPerformReset(context: context)

    #expect(didReset == true)

    // 昨日のタスクが削除されていることを確認
    let descriptor = FetchDescriptor<TodoItem>()
    let remainingTasks = try! context.fetch(descriptor)
    #expect(remainingTasks.count == 0)
  }

  @Test("複数日のタスクが混在している場合")
  @MainActor func testCheckAndPerformResetWithMixedTasks() {
    let context = createTestContext()

    let calendar = Calendar.current

    // 今日のタスク
    let todayTask = TodoItem(content: "今日のタスク")
    todayTask.createdAt = Date()
    context.insert(todayTask)

    // 昨日のタスク
    let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
    let yesterdayTask = TodoItem(content: "昨日のタスク")
    yesterdayTask.createdAt = yesterday
    context.insert(yesterdayTask)

    // リセットチェック実行
    let didReset = AutoResetService.checkAndPerformReset(context: context)

    #expect(didReset == true)

    // 今日のタスクのみ残っていることを確認
    let descriptor = FetchDescriptor<TodoItem>()
    let remainingTasks = try! context.fetch(descriptor)
    #expect(remainingTasks.count == 1)
    #expect(remainingTasks.first?.content == "今日のタスク")
  }

  @Test("境界条件: 午前0時直前のタスクは翌日にリセットされる")
  @MainActor func testCheckAndPerformResetWithBoundaryCondition() {
    let context = createTestContext()

    let calendar = Calendar.current
    let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
    let yesterdayEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: yesterday)!

    let boundaryTask = TodoItem(content: "昨日23:59:59のタスク")
    boundaryTask.createdAt = yesterdayEnd
    context.insert(boundaryTask)

    // リセットチェック実行
    let didReset = AutoResetService.checkAndPerformReset(context: context)

    #expect(didReset == true)

    // タスクが削除されていることを確認
    let descriptor = FetchDescriptor<TodoItem>()
    let remainingTasks = try! context.fetch(descriptor)
    #expect(remainingTasks.count == 0)
  }

  @Test("空のデータベースの場合はリセット不要")
  @MainActor func testCheckAndPerformResetWithEmptyDatabase() {
    let context = createTestContext()

    // リセットチェック実行
    let didReset = AutoResetService.checkAndPerformReset(context: context)

    #expect(didReset == false)

    // タスクが0件のまま
    let descriptor = FetchDescriptor<TodoItem>()
    let remainingTasks = try! context.fetch(descriptor)
    #expect(remainingTasks.count == 0)
  }

  @Test("複数のカテゴリの古いタスクを適切に削除")
  @MainActor func testCheckAndPerformResetWithMultipleDaysAndCategories() {
    let context = createTestContext()
    let calendar = Calendar.current

    // 複数日のタスクを追加
    let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
    let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
    let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date())!

    let todayTask = TodoItem(content: "今日のタスク")
    let yesterdayTask = TodoItem(content: "昨日のタスク")
    let weekAgoTask = TodoItem(content: "1週間前のタスク")
    let tomorrowTask = TodoItem(content: "明日のタスク")

    yesterdayTask.createdAt = yesterday
    weekAgoTask.createdAt = weekAgo
    tomorrowTask.createdAt = tomorrow

    context.insert(todayTask)
    context.insert(yesterdayTask)
    context.insert(weekAgoTask)
    context.insert(tomorrowTask)

    // リセットチェック実行
    let didReset = AutoResetService.checkAndPerformReset(context: context)

    #expect(didReset == true)

    // 今日と明日のタスクのみ残っているはず
    let descriptor = FetchDescriptor<TodoItem>()
    let remainingTasks = try! context.fetch(descriptor)

    #expect(remainingTasks.count == 2)
    #expect(remainingTasks.contains { $0.content == "今日のタスク" })
    #expect(remainingTasks.contains { $0.content == "明日のタスク" })
    #expect(!remainingTasks.contains { $0.content == "昨日のタスク" })
    #expect(!remainingTasks.contains { $0.content == "1週間前のタスク" })
  }
}
