import SwiftUI

struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel = SettingsViewModel(
    settingsRepository: SettingsRepository(modelContext: ModelContainerManager.shared.mainContext)
  )

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Picker("リセット時間", selection: $viewModel.resetTime) {
            ForEach(0..<24, id: \.self) { hour in
              Text("\(hour):00").tag(hour)
            }
          }
          .pickerStyle(.wheel)
        } header: {
          Text("リセット時間")
        } footer: {
          Text("毎日\(viewModel.resetTime):00に、それより前に作成されたタスクが自動的に削除されます")
        }
      }
      .navigationTitle("設定")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("完了") {
            dismiss()
          }
        }
      }
    }
  }
}

#Preview {
  SettingsView()
}
