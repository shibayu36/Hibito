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

  @Test func testIsBeforeResetTime() async throws {
    let calendar = Calendar.current

    // テスト用の基準日時を作成（14:30）
    var components = calendar.dateComponents([.year, .month, .day], from: Date())
    components.hour = 14
    components.minute = 30
    let baseDate = calendar.date(from: components)!

    // リセット時刻が0時の場合（デフォルト）
    // 今日の0時より前のタスクは削除対象
    components.hour = 23
    components.minute = 59
    components.day! -= 1
    let yesterdayNight = calendar.date(from: components)!
    #expect(yesterdayNight.isBeforeResetTime(hour: 0) == true)

    // 今日の1時のタスクは削除対象外
    components.day! += 1
    components.hour = 1
    components.minute = 0
    let todayMorning = calendar.date(from: components)!
    #expect(todayMorning.isBeforeResetTime(hour: 0) == false)
  }

  @Test func testIsBeforeResetTimeVariousHours() async throws {
    let calendar = Calendar.current

    // テスト用の基準日時を作成（14:30）
    var components = calendar.dateComponents([.year, .month, .day], from: Date())
    components.hour = 14
    components.minute = 30
    let now = calendar.date(from: components)!

    // リセット時刻が12時の場合
    // 今日の11:59に作成されたタスクは削除対象
    components.hour = 11
    components.minute = 59
    let beforeNoon = calendar.date(from: components)!
    #expect(beforeNoon.isBeforeResetTime(hour: 12) == true)

    // 今日の12:01に作成されたタスクは削除対象外
    components.hour = 12
    components.minute = 1
    let afterNoon = calendar.date(from: components)!
    #expect(afterNoon.isBeforeResetTime(hour: 12) == false)

    // リセット時刻が18時の場合（現在14:30なので、まだリセット時刻前）
    // 昨日の18時以前のタスクが削除対象
    components.day! -= 1
    components.hour = 17
    components.minute = 59
    let yesterdayEvening = calendar.date(from: components)!
    #expect(yesterdayEvening.isBeforeResetTime(hour: 18) == true)

    // 昨日の18:01のタスクは削除対象外
    components.hour = 18
    components.minute = 1
    let yesterdayAfterReset = calendar.date(from: components)!
    #expect(yesterdayAfterReset.isBeforeResetTime(hour: 18) == false)
  }

  @Test func testIsBeforeResetTimeBoundary() async throws {
    let calendar = Calendar.current

    // ちょうどリセット時刻のケース
    var components = calendar.dateComponents([.year, .month, .day], from: Date())
    components.hour = 6
    components.minute = 0
    let resetTime = calendar.date(from: components)!

    // 1秒前のタスクは削除対象
    let beforeReset = resetTime.addingTimeInterval(-1)
    #expect(beforeReset.isBeforeResetTime(hour: 6) == true)

    // ちょうどリセット時刻のタスクは削除対象外
    #expect(resetTime.isBeforeResetTime(hour: 6) == false)

    // 1秒後のタスクは削除対象外
    let afterReset = resetTime.addingTimeInterval(1)
    #expect(afterReset.isBeforeResetTime(hour: 6) == false)
  }

  @Test func testIsBeforeTodayUsesIsBeforeResetTime() async throws {
    // isBeforeTodayがisBeforeResetTime(hour: 0)を呼んでいることを確認
    let calendar = Calendar.current
    let now = Date()

    // 両方のメソッドが同じ結果を返すことを確認
    let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
    #expect(yesterday.isBeforeToday() == yesterday.isBeforeResetTime(hour: 0))

    let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
    #expect(tomorrow.isBeforeToday() == tomorrow.isBeforeResetTime(hour: 0))

    #expect(now.isBeforeToday() == now.isBeforeResetTime(hour: 0))
  }
}
