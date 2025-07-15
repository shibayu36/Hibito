import Foundation
import SwiftData

@Model
class TodoItem {
  var id = UUID()
  var content: String = ""
  var isCompleted = false
  var order: Double = 0.0
  var createdAt = DateProvider.now

  init(content: String = "", order: Double = 0.0) {
    self.content = content
    self.order = order
  }
}
