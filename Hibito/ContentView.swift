//
//  ContentView.swift
//  Hibito
//
//  Created by Yuki Shibazaki on 2025/06/11.
//

import SwiftUI

struct ContentView: View {
    @State private var viewModel = TodoViewModel()
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Todo list
            if viewModel.items.isEmpty {
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
                .contentShape(Rectangle())
                .onTapGesture {
                    isInputFocused = false
                }
            }

            Divider()

            // Footer with input field
            VStack {
                HStack {
                    TextField("今日やることを追加", text: $viewModel.newItemText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isInputFocused)
                        .onSubmit {
                            viewModel.addItem()
                            isInputFocused = true
                        }

                    Button(action: {
                        viewModel.addItem()
                        isInputFocused = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .disabled(viewModel.newItemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
            .background(.regularMaterial)
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
