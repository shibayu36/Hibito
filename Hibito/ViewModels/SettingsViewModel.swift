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

  var useCloudSync: Bool = false {
    didSet {
      settingsRepository.updateUseCloudSync(useCloudSync)
    }
  }

  init(settingsRepository: SettingsRepository) {
    self.settingsRepository = settingsRepository
    self.resetTime = settingsRepository.getResetTime()
    self.useCloudSync = settingsRepository.getUseCloudSync()
  }
}
