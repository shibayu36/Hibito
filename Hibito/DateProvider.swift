import Foundation

/// 時刻取得を抽象化するプロトコル
/// テスト時の時刻制御と本番時の実時刻取得を統一的に扱う
protocol DateProvider {
  /// 現在時刻を取得
  var now: Date { get }
}

/// 本番・実機用のDateProvider
/// 実際のシステム時刻を返す
struct SystemDateProvider: DateProvider {
  var now: Date { Date() }
}

/// テスト用のDateProvider
/// 固定された時刻を返すため、テスト時の時刻制御が可能
struct MockDateProvider: DateProvider {
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
