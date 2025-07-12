import SwiftData
import Testing

@testable import Hibito

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

  private func createInMemoryContainer() -> ModelContainer {
    let schema = Schema([Settings.self, TodoItem.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try! ModelContainer(for: schema, configurations: [configuration])
  }
}
