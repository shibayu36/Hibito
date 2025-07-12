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
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let thisDate = calendar.startOfDay(for: self)
    return thisDate < today
  }

  /// 今日の指定時刻より前に作成されたかを判定
  func isBeforeTodayTime(hour: Int) -> Bool {
    let calendar = Calendar.current
    let today = Date()

    guard let todayTargetTime = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: today)
    else {
      return false
    }

    return self < todayTargetTime
  }
}
