import Foundation

/// App Storeレビュー促進に必要なデータを管理するRepository
/// 起動日数の記録とレビューリクエスト済みフラグをUserDefaultsで永続化する
@MainActor
class ReviewPromptRepository {
  private let userDefaults: UserDefaults
  private let requiredLaunchDays = 7

  private let launchDayCountKey = "reviewPrompt_launchDayCount"
  private let lastRecordedDateKey = "reviewPrompt_lastRecordedDate"
  private let hasRequestedKey = "reviewPrompt_hasRequested"

  init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  /// アプリがフォアグラウンドになったことを記録する
  /// 同じ日に複数回呼ばれてもカウントは1日分のみ
  func recordAppForeground(now: Date = Date()) {
    let todayString = formatDate(now)
    let lastRecorded = userDefaults.string(forKey: lastRecordedDateKey)

    guard todayString != lastRecorded else { return }

    let currentCount = userDefaults.integer(forKey: launchDayCountKey)
    userDefaults.set(currentCount + 1, forKey: launchDayCountKey)
    userDefaults.set(todayString, forKey: lastRecordedDateKey)
  }

  /// レビューダイアログをリクエストすべきかどうかを判定する
  func shouldRequestReview() -> Bool {
    let count = userDefaults.integer(forKey: launchDayCountKey)
    let hasRequested = userDefaults.bool(forKey: hasRequestedKey)
    return count >= requiredLaunchDays && !hasRequested
  }

  /// レビューリクエスト済みとして記録する
  func markReviewRequested() {
    userDefaults.set(true, forKey: hasRequestedKey)
  }

  private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()

  private func formatDate(_ date: Date) -> String {
    Self.dateFormatter.string(from: date)
  }
}
