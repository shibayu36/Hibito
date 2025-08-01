import Foundation

/// 設定画面のUIロジックを担当するViewModel
@Observable
@MainActor
class SettingsViewModel {
  private let settingsRepository: SettingsRepository
  private let initialUseCloudSync: Bool

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

  var hasCloudSyncSettingChanged: Bool {
    return useCloudSync != initialUseCloudSync
  }

  init(settingsRepository: SettingsRepository) {
    self.settingsRepository = settingsRepository
    self.resetTime = settingsRepository.getResetTime()
    self.useCloudSync = settingsRepository.getUseCloudSync()
    self.initialUseCloudSync = settingsRepository.getUseCloudSync()
  }
}
