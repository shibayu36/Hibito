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
    @State private var showTodoList = false

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

        Button(showTodoList ? "TODOリスト非表示" : "TODOリスト表示") {
          showTodoList.toggle()
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)

        if showTodoList {
          todoListView
        }
      }
      .padding()
      .background(.thinMaterial)
      .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Views

    private var todoListView: some View {
      VStack(alignment: .leading, spacing: 4) {
        Text("TODOリスト詳細 (計\(viewModel.todos.count)件)")
          .font(.caption2)
          .fontWeight(.semibold)
          .foregroundColor(.primary)

        ScrollView {
          LazyVStack(alignment: .leading, spacing: 8) {
            ForEach(Array(viewModel.todos.enumerated()), id: \.element.id) { index, todo in
              VStack(alignment: .leading, spacing: 2) {
                HStack {
                  Text("[\(index + 1)] \(todo.isCompleted ? "✓" : "×")")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(todo.isCompleted ? .green : .red)

                  Spacer()

                  Text("order: \(String(format: "%.1f", todo.order))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }

                Text(todo.content.prefix(50) + (todo.content.count > 50 ? "..." : ""))
                  .font(.caption2)
                  .lineLimit(2)
                  .foregroundColor(.primary)

                Text(dateFormatter.string(from: todo.createdAt))
                  .font(.caption2)
                  .foregroundColor(.secondary)
              }
              .padding(8)
              .background(Color(UIColor.systemGray6))
              .cornerRadius(6)
            }
          }
        }
        .frame(maxHeight: 200)
      }
      .padding(8)
      .background(Color(UIColor.systemGray5))
      .cornerRadius(8)
    }

    private var dateFormatter: DateFormatter {
      let formatter = DateFormatter()
      formatter.dateFormat = "MM/dd HH:mm"
      return formatter
    }

    // MARK: - Debug Methods

    private func createYesterdayTask() {
      let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
      let maxOrder = viewModel.todos.last?.order ?? 0.0
      let item = TodoItem(content: "昨日のタスク", order: maxOrder + 1.0)
      item.createdAt = yesterday
      modelContext.insert(item)
      viewModel.loadTodos()
    }
  }
#endif
