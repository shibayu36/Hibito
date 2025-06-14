//
//  ResetManager.swift
//  Hibito
//
//  Created by Yuki Shibazaki on 2025/06/14.
//

import Foundation
import SwiftData

struct ResetManager {

  /// 日次リセット処理を実行する
  /// 昨日以前に作成されたタスクを削除し、今日以降のタスクは残す
  /// - Parameter context: SwiftDataのModelContext
  /// - Throws: SwiftDataの操作でエラーが発生した場合
  static func performReset(context: ModelContext) throws {
    // 全TodoItemを取得
    let descriptor = FetchDescriptor<TodoItem>()
    let allItems = try context.fetch(descriptor)

    // 昨日以前に作成されたタスクを特定
    let tasksToDelete = allItems.filter { item in
      item.createdAt.isBeforeToday()
    }

    // バッチ削除実行
    for task in tasksToDelete {
      context.delete(task)
    }

    // 変更を保存
    try context.save()
  }
}
