import Foundation

/// 設定画面のUIロジックを担当するViewModel
@Observable
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

  /// 設定の説明文を生成
  func resetTimeDescription() -> String {
    return "毎日\(resetTime):00に、それより前に作成されたタスクが自動的に削除されます"
  }
}
