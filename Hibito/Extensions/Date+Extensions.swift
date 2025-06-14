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
}
