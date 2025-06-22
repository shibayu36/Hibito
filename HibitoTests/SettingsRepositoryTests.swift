//
//  SettingsRepositoryTests.swift
//  HibitoTests
//
//  Created by Yuki Shibazaki on 2025/06/22.
//

import Foundation
import Testing

@testable import Hibito

@Suite("SettingsRepository Tests")
struct SettingsRepositoryTests {

  @Test("デフォルト値は0時")
  func testDefaultResetHour() {
    // テスト用のUserDefaultsを作成
    let userDefaults = UserDefaults(suiteName: "test.settings.default")!
    userDefaults.removePersistentDomain(forName: "test.settings.default")

    let repository = SettingsRepository.createForTesting(userDefaults: userDefaults)

    #expect(repository.resetHour == 0)
  }

  @Test("リセット時刻の保存と読み込み")
  func testSaveAndLoadResetHour() {
    let userDefaults = UserDefaults(suiteName: "test.settings.saveload")!
    userDefaults.removePersistentDomain(forName: "test.settings.saveload")

    let repository = SettingsRepository.createForTesting(userDefaults: userDefaults)

    // 保存
    repository.resetHour = 6
    #expect(repository.resetHour == 6)

    // 別のrepositoryインスタンスでも読み込めることを確認
    let anotherRepository = SettingsRepository.createForTesting(userDefaults: userDefaults)
    #expect(anotherRepository.resetHour == 6)
  }

  @Test("有効な値の範囲（0-23）")
  func testValidResetHourRange() {
    let userDefaults = UserDefaults(suiteName: "test.settings.range")!
    userDefaults.removePersistentDomain(forName: "test.settings.range")

    let repository = SettingsRepository.createForTesting(userDefaults: userDefaults)

    // 最小値
    repository.resetHour = 0
    #expect(repository.resetHour == 0)

    // 最大値
    repository.resetHour = 23
    #expect(repository.resetHour == 23)

    // 中間値
    repository.resetHour = 12
    #expect(repository.resetHour == 12)
  }

  @Test("無効な値の処理")
  func testInvalidResetHourValues() {
    let userDefaults = UserDefaults(suiteName: "test.settings.invalid")!
    userDefaults.removePersistentDomain(forName: "test.settings.invalid")

    let repository = SettingsRepository.createForTesting(userDefaults: userDefaults)

    // 負の値（UserDefaultsのintegerは負の値も保存可能）
    repository.resetHour = -1
    #expect(repository.resetHour == -1)

    // 24以上の値（UserDefaultsのintegerは大きな値も保存可能）
    repository.resetHour = 25
    #expect(repository.resetHour == 25)

    // 注: 実際のアプリケーションでは、ViewModelやUIで0-23の範囲に制限する
  }

  @Test("複数回の更新")
  func testMultipleUpdates() {
    let userDefaults = UserDefaults(suiteName: "test.settings.multiple")!
    userDefaults.removePersistentDomain(forName: "test.settings.multiple")

    let repository = SettingsRepository.createForTesting(userDefaults: userDefaults)

    // 複数回更新
    repository.resetHour = 1
    #expect(repository.resetHour == 1)

    repository.resetHour = 5
    #expect(repository.resetHour == 5)

    repository.resetHour = 23
    #expect(repository.resetHour == 23)

    repository.resetHour = 0
    #expect(repository.resetHour == 0)
  }

  @Test("UserDefaultsへの永続化確認")
  func testPersistenceToUserDefaults() {
    let userDefaults = UserDefaults(suiteName: "test.settings.persistence")!
    userDefaults.removePersistentDomain(forName: "test.settings.persistence")

    let repository = SettingsRepository.createForTesting(userDefaults: userDefaults)

    // 値を設定
    repository.resetHour = 15

    // UserDefaultsから直接取得して確認
    let storedValue = userDefaults.integer(forKey: "resetHour")
    #expect(storedValue == 15)
  }
}
