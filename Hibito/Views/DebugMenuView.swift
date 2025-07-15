//
//  DebugMenuView.swift
//  Hibito
//
//  Created by Yuki Shibazaki on 2025/06/14.
//

#if DEBUG
  import SwiftUI
  import SwiftData

  struct DebugMenuView: View {
    let viewModel: TodoListViewModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
      VStack(spacing: 8) {
        Text("デバッグメニュー")
          .font(.caption)
          .foregroundColor(.secondary)

        Button("昨日のタスク作成") {
          createYesterdayTask()
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.regular)
      }
      .padding()
      .background(.thinMaterial)
      .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Debug Methods

    private func createYesterdayTask() {
      let yesterday =
        Calendar.current.date(byAdding: .day, value: -1, to: DateProvider.now)
        ?? DateProvider.now
      let maxOrder = viewModel.todos.last?.order ?? 0.0
      let item = TodoItem(content: "昨日のタスク", order: maxOrder + 1.0)
      item.createdAt = yesterday
      modelContext.insert(item)
      viewModel.loadTodos()
    }
  }
#endif
