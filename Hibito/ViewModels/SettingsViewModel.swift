import Foundation

/// 設定画面のUIロジックを担当するViewModel
@Observable
@MainActor
class SettingsViewModel {
  private let settingsRepository: SettingsRepository

  init(settingsRepository: SettingsRepository) {
    self.settingsRepository = settingsRepository
  }

  /// リセット時間の取得・設定
  var resetTime: Int {
    get { settingsRepository.getResetTime() }
    set { settingsRepository.updateResetTime(newValue) }
  }
}
