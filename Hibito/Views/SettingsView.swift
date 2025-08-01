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
          #if os(iOS)
            .pickerStyle(.wheel)
          #endif
        } header: {
          Text("リセット時間")
        } footer: {
          Text("毎日\(viewModel.resetTime):00に、それより前に作成されたタスクが自動的に削除されます")
        }

        Section {
          Toggle("iCloud同期", isOn: $viewModel.useCloudSync)
        } header: {
          Text("データ同期")
        } footer: {
          VStack(alignment: .leading, spacing: 8) {
            Text("TODOと設定を複数デバイス間で同期します")
            if viewModel.hasCloudSyncSettingChanged {
              Text("変更を反映するにはアプリを再起動してください")
                .foregroundColor(.orange)
                .font(.caption)
            }
          }
        }
      }
      .navigationTitle("設定")
      #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
      .toolbar {
        #if os(iOS)
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("完了") {
              dismiss()
            }
          }
        #else
          ToolbarItem(placement: .confirmationAction) {
            Button("完了") {
              dismiss()
            }
          }
        #endif
      }
    }
  }
}

#Preview {
  SettingsView()
}
