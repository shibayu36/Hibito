//
//  TodoItemOrderingTests.swift
//  HibitoTests
//
//  Created by Yuki Shibazaki on 2025/06/18.
//

import Foundation
import SwiftData
import Testing

@testable import Hibito

struct TodoItemOrderingTests {

  // MARK: - Setup Helper

  /// テスト用のSwiftDataコンテキストを作成
  @MainActor private func createTestContext() -> ModelContext {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: TodoItem.self, configurations: config)
    return ModelContext(container)
  }

  /// テスト用のTodoItemのリストを作成
  @MainActor private func createTestItems(in context: ModelContext, count: Int) -> [TodoItem] {
    var items: [TodoItem] = []
    for i in 0..<count {
      let item = TodoItem(content: "Task \(i + 1)", order: Double(i + 1))
      context.insert(item)
      items.append(item)
    }
    try! context.save()
    return items
  }

  /// テスト用の軽量アイテム（SwiftDataに依存しない）
  struct TestItem: OrderedItem {
    let content: String
    let order: Double
  }

  // MARK: - OrderingUtility.calculateNewOrderValueのテスト

  @Test("最初の位置に移動する場合のorder値計算")
  func testMoveToFirstPosition() {
    let items = [
      TestItem(content: "Task 1", order: 1.0),
      TestItem(content: "Task 2", order: 2.0),
      TestItem(content: "Task 3", order: 3.0),
    ]

    // Task 2（index: 1）を最初（destination: 0）に移動
    let newOrder = OrderingUtility.calculateNewOrderValue(
      sourceIndex: 1,
      destination: 0,
      items: items
    )

    #expect(newOrder == 0.0)  // 1.0 - 1.0 = 0.0
    #expect(newOrder < items[0].order)
  }

  @Test("最後の位置に移動する場合のorder値計算")
  func testMoveToLastPosition() {
    let items = [
      TestItem(content: "Task 1", order: 1.0),
      TestItem(content: "Task 2", order: 2.0),
      TestItem(content: "Task 3", order: 3.0),
    ]

    // Task 1（index: 0）を最後（destination: 3）に移動
    let newOrder = OrderingUtility.calculateNewOrderValue(
      sourceIndex: 0,
      destination: 3,
      items: items
    )

    #expect(newOrder == 4.0)  // 3.0 + 1.0 = 4.0
    #expect(newOrder > items[2].order)
  }

  @Test("中間の位置に移動する場合のorder値計算")
  func testMoveToMiddlePosition() {
    let items = [
      TestItem(content: "Task 1", order: 1.0),
      TestItem(content: "Task 2", order: 2.0),
      TestItem(content: "Task 3", order: 3.0),
      TestItem(content: "Task 4", order: 4.0),
    ]

    // Task 4（index: 3）を2番目と3番目の間（destination: 2）に移動
    let newOrder = OrderingUtility.calculateNewOrderValue(
      sourceIndex: 3,
      destination: 2,
      items: items
    )

    #expect(newOrder == 2.5)  // (2.0 + 3.0) / 2 = 2.5
    #expect(newOrder > items[1].order)
    #expect(newOrder < items[2].order)
  }

  @Test("actualDestinationの計算（後方への移動）")
  func testActualDestinationCalculationForward() {
    let items = [
      TestItem(content: "Task 1", order: 1.0),
      TestItem(content: "Task 2", order: 2.0),
      TestItem(content: "Task 3", order: 3.0),
    ]

    // sourceIndex(1) < destination(3) の場合、actualDestination = destination - 1 = 2
    // つまり最後に移動
    let newOrder = OrderingUtility.calculateNewOrderValue(
      sourceIndex: 1,
      destination: 3,
      items: items
    )

    #expect(newOrder == 4.0)  // 最後への移動
  }

  @Test("actualDestinationの計算（前方への移動）")
  func testActualDestinationCalculationBackward() {
    let items = [
      TestItem(content: "Task 1", order: 1.0),
      TestItem(content: "Task 2", order: 2.0),
      TestItem(content: "Task 3", order: 3.0),
    ]

    // sourceIndex(2) >= destination(1) の場合、actualDestination = destination = 1
    // つまり1番目と2番目の間に移動
    let newOrder = OrderingUtility.calculateNewOrderValue(
      sourceIndex: 2,
      destination: 1,
      items: items
    )

    #expect(newOrder == 1.5)  // (1.0 + 2.0) / 2 = 1.5
  }

  @Test("空の配列の場合")
  func testEmptyArray() {
    let items: [TestItem] = []

    let newOrder = OrderingUtility.calculateNewOrderValue(
      sourceIndex: 0,
      destination: 0,
      items: items
    )

    #expect(newOrder == 1.0)  // デフォルト値
  }

  @Test("1つの要素の場合")
  func testSingleElement() {
    let items = [TestItem(content: "Task 1", order: 5.0)]

    // 自分自身への移動
    let newOrder = OrderingUtility.calculateNewOrderValue(
      sourceIndex: 0,
      destination: 0,
      items: items
    )

    #expect(newOrder == 4.0)  // 5.0 - 1.0 = 4.0
  }

  @Test("非常に近いorder値での精度テスト")
  func testOrderValuePrecision() {
    let items = [
      TestItem(content: "Task 1", order: 1.0),
      TestItem(content: "Task 2", order: 1.0000001),
    ]

    // Task 2を最初に移動
    let newOrder = OrderingUtility.calculateNewOrderValue(
      sourceIndex: 1,
      destination: 0,
      items: items
    )

    #expect(newOrder == 0.0)  // 1.0 - 1.0 = 0.0
    #expect(newOrder < items[0].order)
  }

  // MARK: - 統合テスト（SwiftDataとの組み合わせ）

  @Test("実際のTodoItemでの統合テスト")
  @MainActor func testWithRealTodoItems() {
    let context = createTestContext()
    let items = createTestItems(in: context, count: 3)

    // Task 2を最初に移動
    let newOrder = OrderingUtility.calculateNewOrderValue(
      sourceIndex: 1,
      destination: 0,
      items: items
    )

    items[1].order = newOrder
    try! context.save()

    // 新しい順序で取得
    let descriptor = FetchDescriptor<TodoItem>(sortBy: [SortDescriptor(\.order)])
    let sortedItems = try! context.fetch(descriptor)

    #expect(sortedItems[0].content == "Task 2")
    #expect(sortedItems[1].content == "Task 1")
    #expect(sortedItems[2].content == "Task 3")
  }

  @Test("複数回の移動後の整合性確認")
  @MainActor func testMultipleMoves() {
    let context = createTestContext()
    let items = createTestItems(in: context, count: 5)

    // 1. Task 3を最初に移動
    let newOrder1 = OrderingUtility.calculateNewOrderValue(
      sourceIndex: 2,
      destination: 0,
      items: items
    )
    items[2].order = newOrder1

    // 2. Task 5を2番目に移動（現在の並び考慮）
    let currentItems = items.sorted { $0.order < $1.order }
    let newOrder2 = OrderingUtility.calculateNewOrderValue(
      sourceIndex: 4,  // 元のTask 5のindex
      destination: 1,
      items: currentItems
    )
    items[4].order = newOrder2

    try! context.save()

    // 最終的な順序を確認
    let descriptor = FetchDescriptor<TodoItem>(sortBy: [SortDescriptor(\.order)])
    let sortedItems = try! context.fetch(descriptor)

    #expect(sortedItems[0].content == "Task 3")
    #expect(sortedItems[1].content == "Task 5")
    // 残りの順序も確認
  }
}
