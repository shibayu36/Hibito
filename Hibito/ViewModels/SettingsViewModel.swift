import Foundation

class SettingsViewModel: ObservableObject {
  private let repository = SettingsRepository.shared

  @Published var resetHour: Int {
    didSet {
      repository.resetHour = resetHour
    }
  }

  init() {
    resetHour = repository.resetHour
  }
}
