import Foundation
import SwiftData

@Model
class TodoItem {
    var id = UUID()
    var content: String = ""
    var isCompleted = false
    
    init(content: String = "", isCompleted: Bool = false) {
        self.content = content
        self.isCompleted = isCompleted
    }
}
