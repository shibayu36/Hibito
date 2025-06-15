//
//  ContentView.swift
//  Hibito
//
//  Created by Yuki Shibazaki on 2025/06/11.
//

import Foundation
import SwiftData
import SwiftUI

struct ContentView: View {
  @Query(sort: \TodoItem.order) private var items: [TodoItem]
  @Environment(\.modelContext) private var modelContext
  @Environment(\.scenePhase) private var scenePhase
  @State private var newItemText = ""
  @FocusState private var isInputFocused: Bool
  @State private var resetTimer: Timer?
  @State private var isPerformingReset = false
  #if DEBUG
    @State private var showDebugMenu = false
  #endif

  var body: some View {
    VStack(spacing: 0) {
      // Header with debug icon
      #if DEBUG
        HStack {
          Spacer()
          Button(action: {
            showDebugMenu.toggle()
          }) {
            Image(systemName: "hammer.circle")
              .font(.title2)
              .foregroundColor(.gray)
          }
          .padding()
        }
        .frame(height: 44)
      #endif

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

      // デバッグメニュー（条件付き表示）
      #if DEBUG
        if showDebugMenu {
          DebugMenu()
        }
      #endif
    }
    .frame(minWidth: 400, minHeight: 500)
    .onAppear {
      performResetCheck()
      startResetTimer()
    }
    .onDisappear {
      stopResetTimer()
    }
    .onChange(of: scenePhase) { _, newPhase in
      switch newPhase {
      case .active:
        performResetCheck()
        startResetTimer()
      case .background, .inactive:
        stopResetTimer()
      @unknown default:
        break
      }
    }
    #if DEBUG
      .animation(.easeInOut(duration: 0.3), value: showDebugMenu)
    #endif
  }

  private func addItem() {
    guard !newItemText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

    let maxOrder = items.last?.order ?? 0.0
    let item = TodoItem(
      content: newItemText.trimmingCharacters(in: .whitespacesAndNewlines), order: maxOrder + 1.0)
    modelContext.insert(item)
    newItemText = ""
  }

  // MARK: - 自動リセット機能

  /// リセットチェックを実行
  private func performResetCheck() {
    guard !isPerformingReset else { return }

    isPerformingReset = true
    withAnimation(.easeOut(duration: 0.5)) {
      _ = AutoResetService.checkAndPerformReset(context: modelContext)
    }
    isPerformingReset = false
  }

  /// Timer監視開始
  private func startResetTimer() {
    stopResetTimer()  // 既存のTimerがあれば停止

    resetTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
      performResetCheck()
    }
    resetTimer?.tolerance = 10.0  // バッテリー効率のためのtolerance
  }

  /// Timer監視停止
  private func stopResetTimer() {
    resetTimer?.invalidate()
    resetTimer = nil
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
