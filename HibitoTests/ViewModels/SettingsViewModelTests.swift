import Foundation
import SwiftData
import Testing

@testable import Hibito

@MainActor
struct SettingsViewModelTests {

  @Test("resetTimeプロパティのバインディングとSwiftData永続化確認")
  func testResetTime() throws {
    let container = createInMemoryContainer()
    let context = ModelContext(container)
    let repository = SettingsRepository(modelContext: context)
    let viewModel = SettingsViewModel(settingsRepository: repository)

    // デフォルト値確認
    #expect(viewModel.resetTime == 0)
    #expect(repository.getResetTime() == 0)

    // 設定値の更新
    viewModel.resetTime = 15
    #expect(viewModel.resetTime == 15)
    #expect(repository.getResetTime() == 15)

    // 再度更新
    viewModel.resetTime = 9
    #expect(viewModel.resetTime == 9)
    #expect(repository.getResetTime() == 9)
  }

  @Test("useCloudSyncプロパティのバインディングとUserDefaults永続化確認")
  func testUseCloudSync() throws {
    let container = createInMemoryContainer()
    let context = ModelContext(container)
    let userDefaults = UserDefaults(suiteName: "testUseCloudSync")!
    userDefaults.removePersistentDomain(forName: "testUseCloudSync")

    let repository = SettingsRepository(modelContext: context, userDefaults: userDefaults)
    let viewModel = SettingsViewModel(settingsRepository: repository)

    // デフォルト値確認
    #expect(viewModel.useCloudSync == false)
    #expect(repository.getUseCloudSync() == false)

    // 設定値の更新（true）
    viewModel.useCloudSync = true
    #expect(viewModel.useCloudSync == true)
    #expect(repository.getUseCloudSync() == true)

    // 再度更新（false）
    viewModel.useCloudSync = false
    #expect(viewModel.useCloudSync == false)
    #expect(repository.getUseCloudSync() == false)
  }

  @Test("useCloudSyncの設定が変わったときだけ、設定変更を正しく検知する")
  func testCloudSyncSettingChangeDetection() throws {
    let container = createInMemoryContainer()
    let context = ModelContext(container)
    let userDefaults = UserDefaults(suiteName: "testCloudSyncSettingChangeInitialTrue")!
    userDefaults.removePersistentDomain(forName: "testCloudSyncSettingChangeInitialTrue")

    // 初期値をtrueに設定
    userDefaults.set(true, forKey: "useCloudSync")

    let repository = SettingsRepository(modelContext: context, userDefaults: userDefaults)
    let viewModel = SettingsViewModel(settingsRepository: repository)

    // 初期状態では変更なし
    #expect(viewModel.useCloudSync == true)
    #expect(viewModel.hasCloudSyncSettingChanged == false)

    // 設定を変更（false）
    viewModel.useCloudSync = false
    #expect(viewModel.hasCloudSyncSettingChanged == true)

    // 元に戻す
    viewModel.useCloudSync = true
    #expect(viewModel.hasCloudSyncSettingChanged == false)
  }

  private func createInMemoryContainer() -> ModelContainer {
    let schema = Schema([Settings.self, TodoItem.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try! ModelContainer(for: schema, configurations: [configuration])
  }
}
