import Foundation
import Testing

@testable import Hibito

struct DateProviderTests {

  @Test("デフォルトで初期化した場合、何回呼んでも同じ値を返す")
  func testDefaultInitialization() {
    DateProvider.setMockDate()
    defer { DateProvider.reset() }

    let firstCall = DateProvider.now
    let secondCall = DateProvider.now

    #expect(firstCall == secondCall)
  }

  @Test("Dateを渡して初期化した場合、何回呼んでも同じ値を返す")
  func testInitializationWithSpecificDate() {
    // 特定の日時で初期化（1970年1月12日 13:46:40 UTC）
    DateProvider.setMockDate(Date(timeIntervalSince1970: 1_000_000))

    let calendar = Calendar.current
    let expectedDate = calendar.date(
      from: DateComponents(
        timeZone: TimeZone(identifier: "UTC"), year: 1970, month: 1, day: 12, hour: 13, minute: 46,
        second: 40))!

    let firstCall = DateProvider.now
    let secondCall = DateProvider.now

    #expect(firstCall == expectedDate)
    #expect(secondCall == expectedDate)

    // リセットしたら元に戻る
    DateProvider.reset()
    #expect(DateProvider.now != expectedDate)
  }

  @Test("setDateでISO8601文字列を指定することで時刻を変更できる")
  func testSetDateWithISO8601String() {
    DateProvider.setMockDate("2025-01-14T15:30:00+09:00")
    defer { DateProvider.reset() }

    let calendar = Calendar.current
    let expectedDate = calendar.date(
      from: DateComponents(
        timeZone: TimeZone(identifier: "Asia/Tokyo"), year: 2025, month: 1, day: 14, hour: 15,
        minute: 30,
        second: 0))!

    #expect(DateProvider.now == expectedDate)
  }
}
