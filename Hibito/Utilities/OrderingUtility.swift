//
//  OrderingUtility.swift
//  Hibito
//
//  Created by Yuki Shibazaki on 2025/06/18.
//

import Foundation

struct OrderingUtility {

  /// 並び替え時の新しいorder値を計算する
  /// - Parameters:
  ///   - sourceIndex: 移動元のインデックス
  ///   - destination: 移動先のインデックス（SwiftUIのonMoveから提供される値）
  ///   - items: 現在のアイテム配列（order値でソート済み）
  /// - Returns: 新しいorder値
  static func calculateNewOrderValue<T: OrderedItem>(
    sourceIndex: Int,
    destination: Int,
    items: [T]
  ) -> Double {
    guard !items.isEmpty else { return 1.0 }

    let actualDestination = sourceIndex < destination ? destination - 1 : destination

    if actualDestination == 0 {
      return (items.first?.order ?? 0.0) - 1.0
    } else if actualDestination >= items.count - 1 {
      return (items.last?.order ?? 0.0) + 1.0
    } else {
      let prevOrder = items[actualDestination - 1].order
      let nextOrder = items[actualDestination].order
      return (prevOrder + nextOrder) / 2.0
    }
  }
}

/// order値を持つアイテムのプロトコル
protocol OrderedItem {
  var order: Double { get }
}

extension TodoItem: OrderedItem {}
