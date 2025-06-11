//
//  ContentView.swift
//  Hibito
//
//  Created by Yuki Shibazaki on 2025/06/11.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = TodoViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Header with input field
            VStack {
                HStack {
                    TextField("今日やることを追加", text: $viewModel.newItemText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            viewModel.addItem()
                        }

                    Button(action: viewModel.addItem) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .disabled(viewModel.newItemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
                            .background(.regularMaterial)

            Divider()

            // Todo list
            List {
                ForEach(viewModel.items) { item in
                    TodoRowView(item: item, viewModel: viewModel)
                }
                .onMove(perform: viewModel.move)
                .onDelete { indexSet in
                    for index in indexSet {
                        viewModel.deleteItem(viewModel.items[index])
                    }
                }
            }
            .listStyle(PlainListStyle())

            // Empty state
            if viewModel.items.isEmpty {
                Spacer()
                Text("今日やることを追加してください")
                    .foregroundColor(.secondary)
                    .padding()
                Spacer()
            }
        }
        .frame(minWidth: 400, minHeight: 500)
    }
}

struct TodoRowView: View {
    let item: TodoItem
    let viewModel: TodoViewModel
    @State private var isEditing = false
    @State private var editText = ""

    var body: some View {
        HStack {
            Button(action: {
                viewModel.toggleCompletion(item)
            }) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isCompleted ? .green : .secondary)
                    .font(.title3)
            }
            .buttonStyle(PlainButtonStyle())

            if isEditing {
                TextField("", text: $editText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        if !editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            item.content = editText.trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        isEditing = false
                    }
                    .onAppear {
                        editText = item.content
                    }
            } else {
                Text(item.content)
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        isEditing = true
                    }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
}
