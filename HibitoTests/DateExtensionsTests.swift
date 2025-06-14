//
//  DateExtensionsTests.swift
//  HibitoTests
//
//  Created by Yuki Shibazaki on 2025/06/14.
//

import Foundation
import Testing

@testable import Hibito

struct DateExtensionsTests {

  @Test func testIsBeforeToday() async throws {
    let calendar = Calendar.current
    let now = Date()

    // 今日の日付は false になるべき
    #expect(now.isBeforeToday() == false)

    // 今日の異なる時刻も false になるべき
    let todayMorning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: now)!
    let todayEvening = calendar.date(bySettingHour: 22, minute: 30, second: 45, of: now)!

    #expect(todayMorning.isBeforeToday() == false)
    #expect(todayEvening.isBeforeToday() == false)

    // 昨日は true になるべき
    let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
    #expect(yesterday.isBeforeToday() == true)

    // 1週間前は true になるべき
    let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
    #expect(weekAgo.isBeforeToday() == true)

    // 明日は false になるべき
    let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
    #expect(tomorrow.isBeforeToday() == false)
  }

  @Test func testBoundaryConditions() async throws {
    let calendar = Calendar.current
    let baseDate = Date()

    // 23:59:59（今日）は false になるべき
    let todayEndOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: baseDate)!
    #expect(todayEndOfDay.isBeforeToday() == false)

    // 00:00:00（今日）は false になるべき
    let todayStartOfDay = calendar.startOfDay(for: baseDate)
    #expect(todayStartOfDay.isBeforeToday() == false)

    // 昨日の23:59:59は true になるべき
    let yesterday = calendar.date(byAdding: .day, value: -1, to: baseDate)!
    let yesterdayEndOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: yesterday)!
    #expect(yesterdayEndOfDay.isBeforeToday() == true)
  }
}
