import Foundation
import SwiftData

/// 自動リセット機能の管理を行うサービスクラス
struct AutoResetService {

  /// リセットが必要かチェックし、必要であれば実行する
  /// - Parameter context: SwiftDataのModelContext
  /// - Returns: リセットを実行した場合はtrue
  @MainActor
  static func checkAndPerformReset(context: ModelContext) -> Bool {
    let descriptor = FetchDescriptor<TodoItem>()
    guard let allItems = try? context.fetch(descriptor) else {
      return false
    }

    // 昨日以前に作成されたタスクを特定
    let tasksToDelete = allItems.filter { item in
      item.createdAt.isBeforeToday()
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
