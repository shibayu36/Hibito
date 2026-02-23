import Foundation
import SwiftData
import Testing

@testable import DailyDo

@MainActor
struct SettingsRepositoryTests {

  @Test("保存していないときはデフォルトで0を返す")
  func getResetTimeReturnsDefaultValue() throws {
    let container = createInMemoryContainer()
    let context = ModelContext(container)
    let repository = SettingsRepository(modelContext: context)

    #expect(repository.getResetTime() == 0)
  }

  @Test("updateResetTimeで設定してからgetResetTimeすると設定された値を返す")
  func updateAndGetResetTime() throws {
    let container = createInMemoryContainer()
    let context = ModelContext(container)
    let repository = SettingsRepository(modelContext: context)

    repository.updateResetTime(12)
    #expect(repository.getResetTime() == 12)

    repository.updateResetTime(18)
    #expect(repository.getResetTime() == 18)
  }

  @Test("複数のSettingsが存在する場合の重複排除処理")
  func duplicateSettingsRemoval() throws {
    let container = createInMemoryContainer()
    let context = ModelContext(container)

    // 複数のSettingsを手動で作成
    let settings1 = Settings(resetTime: 6)
    let settings2 = Settings(resetTime: 12)
    context.insert(settings1)
    context.insert(settings2)
    try context.save()

    let repository = SettingsRepository(modelContext: context)

    // getResetTimeを呼び出して重複削除を実行
    _ = repository.getResetTime()

    // 1つだけ残っていることを確認
    let descriptor = FetchDescriptor<Settings>()
    let allSettings = try context.fetch(descriptor)
    #expect(allSettings.count == 1)
  }

  @Test("iCloud同期設定の更新と取得")
  func updateAndGetUseCloudSync() throws {
    let container = createInMemoryContainer()
    let context = ModelContext(container)
    let testUserDefaults = UserDefaults(suiteName: "test.settings.repository")!
    testUserDefaults.removePersistentDomain(forName: "test.settings.repository")
    let repository = SettingsRepository(modelContext: context, userDefaults: testUserDefaults)

    #expect(repository.getUseCloudSync() == false)

    repository.updateUseCloudSync(true)
    #expect(repository.getUseCloudSync() == true)

    repository.updateUseCloudSync(false)
    #expect(repository.getUseCloudSync() == false)
  }

  private func createInMemoryContainer() -> ModelContainer {
    let schema = Schema([Settings.self, TodoItem.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try! ModelContainer(for: schema, configurations: [configuration])
  }
}
