//
//  SettingsRepository.swift
//  Hibito
//
//  Created by Yuki Shibazaki on 2025/06/22.
//

import Foundation

/// アプリケーション設定の永続化を管理するリポジトリ
class SettingsRepository {
  // MARK: - Properties

  private let userDefaults: UserDefaults
  private let resetHourKey = "resetHour"

  // MARK: - Singleton

  static let shared = SettingsRepository()

  // MARK: - Initialization

  private init(userDefaults: UserDefaults = .standard) {
    self.userDefaults = userDefaults
  }

  // MARK: - Public Methods

  /// リセット時刻（時）を取得
  var resetHour: Int {
    get {
      userDefaults.integer(forKey: resetHourKey)
    }
    set {
      userDefaults.set(newValue, forKey: resetHourKey)
    }
  }

  // MARK: - Testing Support

  #if DEBUG
    /// テスト用の初期化メソッド
    static func createForTesting(userDefaults: UserDefaults) -> SettingsRepository {
      return SettingsRepository(userDefaults: userDefaults)
    }
  #endif
}
