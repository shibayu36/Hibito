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

          Button("設定時刻テスト") {
            createResetTimeTestTasks()
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
        }

        HStack(spacing: 12) {
          Button("全削除") {
            clearAllTasks()
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
          .foregroundColor(.red)

          Button("TODO情報出力") {
            printTodoInfo()
          }
          .buttonStyle(.bordered)
          .controlSize(.small)
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

    private func createResetTimeTestTasks() {
      let resetHour = SettingsRepository.shared.resetHour
      let calendar = Calendar.current
      var maxOrder = items.last?.order ?? 0.0

      // 今日のリセット時刻を計算
      var todayResetComponents = calendar.dateComponents([.year, .month, .day], from: Date())
      todayResetComponents.hour = resetHour
      todayResetComponents.minute = 0
      let todayResetTime = calendar.date(from: todayResetComponents)!

      // リセット時刻の1分前のタスク（削除対象）
      let beforeResetTime = todayResetTime.addingTimeInterval(-60)
      let beforeItem = TodoItem(content: "\(resetHour)時の1分前のタスク", order: maxOrder + 1.0)
      beforeItem.createdAt = beforeResetTime
      modelContext.insert(beforeItem)
      maxOrder += 1.0

      // リセット時刻ちょうどのタスク（削除対象外）
      let exactResetItem = TodoItem(content: "\(resetHour)時ちょうどのタスク", order: maxOrder + 1.0)
      exactResetItem.createdAt = todayResetTime
      modelContext.insert(exactResetItem)
      maxOrder += 1.0

      // リセット時刻の1分後のタスク（削除対象外）
      let afterResetTime = todayResetTime.addingTimeInterval(60)
      let afterItem = TodoItem(content: "\(resetHour)時の1分後のタスク", order: maxOrder + 1.0)
      afterItem.createdAt = afterResetTime
      modelContext.insert(afterItem)
    }

    private func clearAllTasks() {
      for item in items {
        modelContext.delete(item)
      }
    }

    private func performReset() {
      _ = AutoResetService.checkAndPerformReset(context: modelContext)
    }

    private func printTodoInfo() {
      let resetHour = SettingsRepository.shared.resetHour
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

      print("=== TODO情報出力 ===")
      print("現在時刻: \(formatter.string(from: Date()))")
      print("設定リセット時刻: \(resetHour)時")
      print("総タスク数: \(items.count)")
      print("")

      if items.isEmpty {
        print("タスクはありません")
      } else {
        for (index, item) in items.enumerated() {
          let isBeforeReset = item.createdAt.isBeforeResetTime(hour: resetHour)
          let isBeforeToday = item.createdAt.isBeforeToday()

          print("[\(index + 1)] \(item.content)")
          print("  ID: \(item.id)")
          print("  作成日時: \(formatter.string(from: item.createdAt))")
          print("  完了状態: \(item.isCompleted ? "完了" : "未完了")")
          print("  表示順序: \(item.order)")
          print("  リセット時刻より前: \(isBeforeReset ? "はい" : "いいえ")")
          print("  今日より前(旧判定): \(isBeforeToday ? "はい" : "いいえ")")
          print("")
        }
      }
      print("==================")
    }
  }
#endif
