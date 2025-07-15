import Foundation

// このプロジェクトではDateProvider.now()から現在時刻を取得する
// テスト時にはDateProvider.setCurrent()でモックを設定する
class DateProvider {
  static var current: DateProviderProtocol = SystemDateProvider()

  /// 現在の時刻を取得
  static var now: Date {
    current.now
  }

  /// テスト時などに現在のDateProviderを変更
  static func setMock() -> (MockDateProvider, () -> Void) {
    let provider = MockDateProvider()
    let original = current
    current = provider
    return (
      provider,
      {
        current = original
      }
    )
  }
}

/// 時刻取得を抽象化するプロトコル
/// テスト時の時刻制御と本番時の実時刻取得を統一的に扱う
protocol DateProviderProtocol {
  /// 現在時刻を取得
  var now: Date { get }
}

/// 本番・実機用のDateProvider
/// 実際のシステム時刻を返す
struct SystemDateProvider: DateProviderProtocol {
  var now: Date { Date() }
}

/// テスト用のDateProvider
/// 固定された時刻を返すため、テスト時の時刻制御が可能
struct MockDateProvider: DateProviderProtocol {
  private(set) var fixedDate: Date
  var now: Date { fixedDate }

  init(fixedDate: Date = Date()) {
    self.fixedDate = fixedDate
  }

  /// ISO8601形式の文字列から時刻を設定
  /// - Parameter iso8601String: ISO8601形式の日時文字列 (例: "2025-01-14T10:30:00+09:00")
  mutating func setDate(_ iso8601String: String) {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withTimeZone]

    if let date = formatter.date(from: iso8601String) {
      self.fixedDate = date
    }
  }
}
