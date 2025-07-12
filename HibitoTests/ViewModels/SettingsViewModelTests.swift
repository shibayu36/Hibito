import SwiftData
import Testing

@testable import Hibito

struct SettingsViewModelTests {

  @Test("resetTimeプロパティのバインディング確認")
  func resetTimeBinding() throws {
    let container = createInMemoryContainer()
    let context = ModelContext(container)
    let repository = SettingsRepository(modelContext: context)
    let viewModel = SettingsViewModel(settingsRepository: repository)

    // デフォルト値確認
    #expect(viewModel.resetTime == 0)

    // 設定値の更新
    viewModel.resetTime = 15
    #expect(viewModel.resetTime == 15)

    // 再度更新
    viewModel.resetTime = 9
    #expect(viewModel.resetTime == 9)
  }

  private func createInMemoryContainer() -> ModelContainer {
    let schema = Schema([Settings.self, TodoItem.self])
    let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try! ModelContainer(for: schema, configurations: [configuration])
  }
}
