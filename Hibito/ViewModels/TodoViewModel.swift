import Foundation
import SwiftUI

@Observable
class TodoViewModel {
    var items: [TodoItem] = []
    var newItemText = ""

    func addItem() {
        guard !newItemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let item = TodoItem()
        item.content = newItemText.trimmingCharacters(in: .whitespacesAndNewlines)
        items.append(item)
        newItemText = ""
    }

    func toggleCompletion(_ item: TodoItem) {
        item.isCompleted.toggle()
    }

    func deleteItem(_ item: TodoItem) {
        items.removeAll { $0.id == item.id }
    }

    func move(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
}