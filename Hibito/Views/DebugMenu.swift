//
//  DebugMenu.swift
//  Hibito
//
//  Created by Yuki Shibazaki on 2025/06/14.
//

#if DEBUG
  import SwiftUI
  import SwiftData

  struct DebugMenu: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TodoItem.order) private var items: [TodoItem]

    var body: some View {
      VStack(spacing: 8) {
        Text("リセット機能テスト")
          .font(.caption)
          .foregroundColor(.secondary)

        HStack(spacing: 12) {
          Button("昨日のタスク") {
            createYesterdayTask()
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.small)

          Button("一昨日のタスク") {
            createDayBeforeYesterdayTask()
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.small)
        }

        HStack(spacing: 12) {
          Button("境界値テスト") {
            createBoundaryTask()
          }
          .buttonStyle(.bordered)
          .controlSize(.small)

          Button("全削除") {
            clearAllTasks()
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
          .foregroundColor(.red)
        }

        Button("リセット実行") {
          performReset()
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
        .foregroundColor(.white)
        .background(.red)
      }
      .padding()
      .background(.thinMaterial)
      .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Debug Methods

    private func createYesterdayTask() {
      let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
      let maxOrder = items.last?.order ?? 0.0
      let item = TodoItem(content: "昨日のタスク", order: maxOrder + 1.0)
      item.createdAt = yesterday
      modelContext.insert(item)
    }

    private func createDayBeforeYesterdayTask() {
      let dayBefore = Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
      let maxOrder = items.last?.order ?? 0.0
      let item = TodoItem(content: "一昨日のタスク", order: maxOrder + 1.0)
      item.createdAt = dayBefore
      modelContext.insert(item)
    }

    private func createBoundaryTask() {
      // 昨日の23:59:59のタスクを作成
      let calendar = Calendar.current
      let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
      let endOfYesterday =
        calendar.date(bySettingHour: 23, minute: 59, second: 59, of: yesterday) ?? yesterday

      let maxOrder = items.last?.order ?? 0.0
      let item = TodoItem(content: "昨日23:59:59のタスク", order: maxOrder + 1.0)
      item.createdAt = endOfYesterday
      modelContext.insert(item)
    }

    private func clearAllTasks() {
      for item in items {
        modelContext.delete(item)
      }
    }

    private func performReset() {
      do {
        try ResetManager.performReset(context: modelContext)
      } catch {
        print("リセットエラー: \(error)")
      }
    }
  }
#endif
