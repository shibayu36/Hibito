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
            ForEach(viewModel.todos) { todo in

              VStack(alignment: .leading, spacing: 2) {
                HStack {
                  Text("\(todo.isCompleted ? "✓" : "×")")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(todo.isCompleted ? .green : .red)

                  Spacer()

                  Text("order: \(todo.order, specifier: "%.3f")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }

                Text(todo.content)
                  .font(.caption2)
                  .lineLimit(2)
                  .truncationMode(.tail)
                  .foregroundColor(.primary)

                Text(dateFormatter.string(from: todo.createdAt))
                  .font(.caption2)
                  .foregroundColor(.secondary)
              }
              .padding(8)
              .background(Color.gray.opacity(0.1))
              .cornerRadius(6)
            }
          }
        }
        .frame(maxHeight: 200)
      }
      .padding(8)
      .background(Color.gray.opacity(0.2))
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
      let newOrder = TodoItem.generateNewOrder()
      let item = TodoItem(content: "昨日のタスク", order: newOrder)
      item.createdAt = yesterday
      modelContext.insert(item)
      viewModel.loadTodos()
    }
  }
#endif
