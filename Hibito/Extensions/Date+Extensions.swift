//
//  Date+Extensions.swift
//  Hibito
//
//  Created by Yuki Shibazaki on 2025/06/14.
//

import Foundation

extension Date {
  /// 今日より前の日付かどうかを判定する
  func isBeforeToday() -> Bool {
    // デフォルトの0時を使用
    return isBeforeResetTime(hour: 0)
  }

  /// 設定されたリセット時刻より前かどうかを判定
  func isBeforeResetTime(hour: Int) -> Bool {
    let calendar = Calendar.current
    let now = Date()

    // 今日のリセット時刻を計算（分は0固定）
    var todayResetComponents = calendar.dateComponents([.year, .month, .day], from: now)
    todayResetComponents.hour = hour
    todayResetComponents.minute = 0
    let todayResetTime = calendar.date(from: todayResetComponents)!

    // 現在時刻がリセット時刻を過ぎているか
    if now >= todayResetTime {
      // 過ぎている場合：今日のリセット時刻より前のタスクが削除対象
      return self < todayResetTime
    } else {
      // 過ぎていない場合：昨日のリセット時刻より前のタスクが削除対象
      let yesterdayResetTime = calendar.date(byAdding: .day, value: -1, to: todayResetTime)!
      return self < yesterdayResetTime
    }
  }
}
