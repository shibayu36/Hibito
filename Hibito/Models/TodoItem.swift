import Foundation
import SwiftData

@Model
class TodoItem {
  var id = UUID()
  var content: String = ""
  var isCompleted = false
  var order: Double = 0.0
  var createdAt = Date()

  init(content: String = "", order: Double = 0.0) {
    self.content = content
    self.order = order
  }

  /// 新しいTodoアイテム用のorder値を生成します
  /// timeIntervalSince1970ベースで重複のない値を生成
  /// 複数端末で使用していても、iCloud同期時に順序が安定するよう設計
  static func generateNewOrder() -> Double {
    return Date().timeIntervalSince1970
  }
}
