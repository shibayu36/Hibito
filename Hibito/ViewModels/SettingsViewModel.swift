import Foundation

/// 設定画面のUIロジックを担当するViewModel
@Observable
@MainActor
class SettingsViewModel {
  private let settingsRepository: SettingsRepository

  var resetTime: Int = 0 {
    didSet {
      print("🔧 resetTime changed to \(resetTime)")
      settingsRepository.updateResetTime(resetTime)
    }
  }

  var useCloudSync: Bool = false {
    didSet {
      print("🔧 useCloudSync changed to \(useCloudSync)")
      settingsRepository.updateCloudSyncEnabled(useCloudSync)
    }
  }

  init(settingsRepository: SettingsRepository) {
    print("🔧 SettingsViewModel init called")
    self.settingsRepository = settingsRepository
    self.resetTime = settingsRepository.getResetTime()
    self.useCloudSync = settingsRepository.getCloudSyncEnabled()
  }
}
