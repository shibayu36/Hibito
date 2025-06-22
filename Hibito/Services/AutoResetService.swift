import Foundation
import SwiftData

/// 自動リセット機能の管理を行うサービスクラス
struct AutoResetService {

  /// リセットが必要かチェックし、必要であれば実行する
  /// - Parameter context: SwiftDataのModelContext
  /// - Returns: リセットを実行した場合はtrue
  @MainActor
  static func checkAndPerformReset(context: ModelContext) -> Bool {
    let resetHour = SettingsRepository.shared.resetHour

    let descriptor = FetchDescriptor<TodoItem>()
    guard let allItems = try? context.fetch(descriptor) else {
      return false
    }

    // 設定時刻より前に作成されたタスクを特定
    let tasksToDelete = allItems.filter { item in
      item.createdAt.isBeforeResetTime(hour: resetHour)
    }

    // 古いタスクがない場合は何もしない
    guard !tasksToDelete.isEmpty else {
      return false
    }

    // バッチ削除実行
    for task in tasksToDelete {
      context.delete(task)
    }

    // 変更を保存
    try? context.save()

    return true
  }
}
