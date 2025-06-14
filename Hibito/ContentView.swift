//
//  ContentView.swift
//  Hibito
//
//  Created by Yuki Shibazaki on 2025/06/11.
//

import SwiftData
import SwiftUI

struct ContentView: View {
  @Query(sort: \TodoItem.order) private var items: [TodoItem]
  @Environment(\.modelContext) private var modelContext
  @State private var newItemText = ""
  @FocusState private var isInputFocused: Bool

  var body: some View {
    VStack(spacing: 0) {
      // Todo list
      if items.isEmpty {
        // Empty state
        Spacer()
        Text("今日やることを追加してください")
          .foregroundColor(.secondary)
          .padding()
        Spacer()
          .contentShape(Rectangle())
          .onTapGesture {
            isInputFocused = false
          }
      } else {
        List {
          ForEach(items) { item in
            TodoRowView(item: item)
          }
          .onDelete { indexSet in
            for index in indexSet {
              modelContext.delete(items[index])
            }
          }
        }
        .listStyle(PlainListStyle())
      }

      Divider()

      // Footer with input field
      VStack {
        HStack {
          TextField("今日やることを追加", text: $newItemText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .focused($isInputFocused)
            .onSubmit {
              addItem()
              isInputFocused = true
            }

          Button(action: {
            addItem()
            isInputFocused = true
          }) {
            Image(systemName: "plus.circle.fill")
              .font(.title2)
          }
          .disabled(newItemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
      }
      .background(.regularMaterial)
    }
    .frame(minWidth: 400, minHeight: 500)
  }

  private func addItem() {
    guard !newItemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

    let maxOrder = items.last?.order ?? 0.0
    let item = TodoItem(
      content: newItemText.trimmingCharacters(in: .whitespacesAndNewlines), order: maxOrder + 1.0)
    modelContext.insert(item)
    newItemText = ""

  }
}

struct TodoRowView: View {
  let item: TodoItem
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    HStack {
      Button(action: {
        item.isCompleted.toggle()
      }) {
        Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
          .foregroundColor(item.isCompleted ? .green : .secondary)
          .font(.title3)
      }
      .buttonStyle(PlainButtonStyle())

      Text(item.content)
        .strikethrough(item.isCompleted)
        .foregroundColor(item.isCompleted ? .secondary : .primary)
        .frame(maxWidth: .infinity, alignment: .leading)

      Spacer()
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  ContentView()
}
