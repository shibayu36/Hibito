import Foundation
import SwiftData

/// アプリ設定データのSwiftDataアクセスを担当するRepository
class SettingsRepository {
  private let modelContext: ModelContext

  init(modelContext: ModelContext) {
    self.modelContext = modelContext
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

  private func getSettings() -> Settings {
    let descriptor = FetchDescriptor<Settings>()
    let settings = try? modelContext.fetch(descriptor).first

    if let existingSettings = settings {
      return existingSettings
    } else {
      let newSettings = Settings(resetTime: 0)
      modelContext.insert(newSettings)
      try? modelContext.save()
      return newSettings
    }
  }
}
