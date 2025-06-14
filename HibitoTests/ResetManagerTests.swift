//
//  ResetManagerTests.swift
//  HibitoTests
//
//  Created by Yuki Shibazaki on 2025/06/14.
//

import Foundation
import SwiftData
import Testing

@testable import Hibito

struct ResetManagerTests {

  // テスト用のSwiftDataコンテキストを作成
  private func createTestContext() throws -> ModelContext {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: TodoItem.self, configurations: config)
    return ModelContext(container)
  }

  @Test func testPerformResetWithOnlyTodayTasks() async throws {
    let context = try createTestContext()

    // 今日のタスクを追加
    let todayTask1 = TodoItem(content: "今日のタスク1")
    let todayTask2 = TodoItem(content: "今日のタスク2")

    context.insert(todayTask1)
    context.insert(todayTask2)
    try context.save()

    // リセット実行
    try ResetManager.performReset(context: context)

    // 今日のタスクは残っているはず
    let descriptor = FetchDescriptor<TodoItem>()
    let remainingTasks = try context.fetch(descriptor)

    #expect(remainingTasks.count == 2)
    #expect(remainingTasks.contains { $0.content == "今日のタスク1" })
    #expect(remainingTasks.contains { $0.content == "今日のタスク2" })
  }

  @Test func testPerformResetWithOnlyYesterdayTasks() async throws {
    let context = try createTestContext()
    let calendar = Calendar.current

    // 昨日のタスクを追加
    let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
    let yesterdayTask1 = TodoItem(content: "昨日のタスク1")
    let yesterdayTask2 = TodoItem(content: "昨日のタスク2")

    yesterdayTask1.createdAt = yesterday
    yesterdayTask2.createdAt = yesterday

    context.insert(yesterdayTask1)
    context.insert(yesterdayTask2)
    try context.save()

    // リセット実行
    try ResetManager.performReset(context: context)

    // 昨日のタスクは削除されているはず
    let descriptor = FetchDescriptor<TodoItem>()
    let remainingTasks = try context.fetch(descriptor)

    #expect(remainingTasks.count == 0)
  }

  @Test func testPerformResetWithMixedTasks() async throws {
    let context = try createTestContext()
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
    try context.save()

    // リセット実行
    try ResetManager.performReset(context: context)

    // 今日と明日のタスクのみ残っているはず
    let descriptor = FetchDescriptor<TodoItem>()
    let remainingTasks = try context.fetch(descriptor)

    #expect(remainingTasks.count == 2)
    #expect(remainingTasks.contains { $0.content == "今日のタスク" })
    #expect(remainingTasks.contains { $0.content == "明日のタスク" })
    #expect(!remainingTasks.contains { $0.content == "昨日のタスク" })
    #expect(!remainingTasks.contains { $0.content == "1週間前のタスク" })
  }

  @Test func testPerformResetWithBoundaryConditions() async throws {
    let context = try createTestContext()
    let calendar = Calendar.current
    let baseDate = Date()

    // 境界条件のタスクを追加
    let todayStart = calendar.startOfDay(for: baseDate)
    let todayEnd = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: baseDate)!
    let yesterdayEnd = calendar.date(byAdding: .day, value: -1, to: todayStart)!.addingTimeInterval(
      -1)

    let todayStartTask = TodoItem(content: "今日00:00:00のタスク")
    let todayEndTask = TodoItem(content: "今日23:59:59のタスク")
    let yesterdayEndTask = TodoItem(content: "昨日23:59:59のタスク")

    todayStartTask.createdAt = todayStart
    todayEndTask.createdAt = todayEnd
    yesterdayEndTask.createdAt = yesterdayEnd

    context.insert(todayStartTask)
    context.insert(todayEndTask)
    context.insert(yesterdayEndTask)
    try context.save()

    // リセット実行
    try ResetManager.performReset(context: context)

    // 今日のタスクのみ残っているはず
    let descriptor = FetchDescriptor<TodoItem>()
    let remainingTasks = try context.fetch(descriptor)

    #expect(remainingTasks.count == 2)
    #expect(remainingTasks.contains { $0.content == "今日00:00:00のタスク" })
    #expect(remainingTasks.contains { $0.content == "今日23:59:59のタスク" })
    #expect(!remainingTasks.contains { $0.content == "昨日23:59:59のタスク" })
  }

  @Test func testPerformResetWithEmptyDatabase() async throws {
    let context = try createTestContext()

    // 空のデータベースでリセット実行
    try ResetManager.performReset(context: context)

    // エラーが発生せず、タスクも0件のまま
    let descriptor = FetchDescriptor<TodoItem>()
    let remainingTasks = try context.fetch(descriptor)

    #expect(remainingTasks.count == 0)
  }
}
