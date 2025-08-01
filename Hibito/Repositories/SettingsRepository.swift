import Foundation
import SwiftData

/// アプリ設定データのSwiftDataアクセスを担当するRepository
@MainActor
class SettingsRepository {
  private let modelContext: ModelContext
  private let userDefaults: UserDefaults

  init(modelContext: ModelContext, userDefaults: UserDefaults = .standard) {
    self.modelContext = modelContext
    self.userDefaults = userDefaults
  }

  /// 現在のリセット時間を取得
  func getResetTime() -> Int {
    return getSettings().resetTime
  }

  /// リセット時間を更新
  func updateResetTime(_ resetTime: Int) {
    let settings = getSettings()
    settings.resetTime = resetTime
    try? modelContext.save()
  }

  /// iCloud同期設定を取得
  func getUseCloudSync() -> Bool {
    return userDefaults.bool(forKey: "useCloudSync")
  }

  /// iCloud同期設定を更新
  func updateUseCloudSync(_ enabled: Bool) {
    userDefaults.set(enabled, forKey: "useCloudSync")
  }

  private func getSettings() -> Settings {
    let descriptor = FetchDescriptor<Settings>()
    let allSettings = try? modelContext.fetch(descriptor)

    // 複数のSettingsが存在する場合は最初の1つ以外を削除
    // iCloud syncを利用していたとき、複数のSettingsが存在することがある
    if let settings = allSettings, settings.count > 1 {
      for i in 1..<settings.count {
        modelContext.delete(settings[i])
      }
      try? modelContext.save()
    }

    if let existingSettings = allSettings?.first {
      return existingSettings
    } else {
      let newSettings = Settings(resetTime: 0)
      modelContext.insert(newSettings)
      try? modelContext.save()
      return newSettings
    }
  }
}
