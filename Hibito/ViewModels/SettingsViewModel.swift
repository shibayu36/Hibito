import Foundation

/// 設定画面のUIロジックを担当するViewModel
@Observable
@MainActor
class SettingsViewModel {
  private let settingsRepository: SettingsRepository

  var resetTime: Int = 0 {
    didSet {
      settingsRepository.updateResetTime(resetTime)
    }
  }

  init(settingsRepository: SettingsRepository) {
    self.settingsRepository = settingsRepository
    self.resetTime = settingsRepository.getResetTime()
  }
}
