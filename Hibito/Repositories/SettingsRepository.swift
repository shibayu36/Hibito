import Foundation
import SwiftData

/// アプリ設定データのSwiftDataアクセスを担当するRepository
@MainActor
class SettingsRepository {
  private let modelContext: ModelContext

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
  }

  /// 現在のリセット時間を取得
  func getResetTime() -> Int {
    print("🔧 getResetTime() called")
    let result = getSettings().resetTime
    print("🔧 getResetTime() result: \(result)")
    return result
  }

  /// リセット時間を更新
  func updateResetTime(_ resetTime: Int) {
    let settings = getSettings()
    settings.resetTime = resetTime
    try? modelContext.save()
  }

  /// iCloud同期設定を取得
  func getCloudSyncEnabled() -> Bool {
    return UserDefaults.standard.bool(forKey: "useCloudSync")
  }

  /// iCloud同期設定を更新
  func updateCloudSyncEnabled(_ enabled: Bool) {
    UserDefaults.standard.set(enabled, forKey: "useCloudSync")
  }

  private func getSettings() -> Settings {
    let descriptor = FetchDescriptor<Settings>()
    let allSettings = (try? modelContext.fetch(descriptor)) ?? []

    print("🔧 allSettings.count: \(allSettings.count)")

    if let first = allSettings.first {
      // 2件以上ある場合は重複を削除
      if allSettings.count > 1 {
        allSettings.dropFirst().forEach { modelContext.delete($0) }
        try? modelContext.save()
      }
      return first
    }

    let newSettings = Settings(resetTime: 0)
    modelContext.insert(newSettings)
    try? modelContext.save()
    return newSettings
  }
}
