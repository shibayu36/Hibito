import SwiftUI

struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var viewModel = SettingsViewModel(
    settingsRepository: SettingsRepository(modelContext: ModelContainerManager.shared.mainContext)
  )

  var body: some View {
    #if os(iOS)
      SettingsView_iOS(viewModel: viewModel, dismiss: dismiss)
    #else
      SettingsView_macOS(viewModel: viewModel, dismiss: dismiss)
    #endif
  }
}

// MARK: - iOS Settings View
#if os(iOS)
  struct SettingsView_iOS: View {
    @Bindable var viewModel: SettingsViewModel
    let dismiss: DismissAction

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
#endif

// MARK: - macOS Settings View
#if os(macOS)
  struct SettingsView_macOS: View {
    @Bindable var viewModel: SettingsViewModel
    let dismiss: DismissAction

    var body: some View {
      VStack(spacing: 20) {
        HStack {
          Text("設定")
            .font(.title2)
            .fontWeight(.semibold)
          Spacer()
        }
        .padding()

        Form {
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Text("リセット時間")
              Spacer()
              Picker("", selection: $viewModel.resetTime) {
                ForEach(0..<24, id: \.self) { hour in
                  Text("\(hour):00").tag(hour)
                }
              }
              .frame(width: 100)
            }
            Text("毎日\(viewModel.resetTime):00に、それより前に作成されたタスクが自動的に削除されます")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Toggle("iCloud同期", isOn: $viewModel.useCloudSync)
            }
            VStack(alignment: .leading, spacing: 4) {
              Text("TODOと設定を複数デバイス間で同期します")
                .font(.caption)
                .foregroundColor(.secondary)
              if viewModel.hasCloudSyncSettingChanged {
                Text("変更を反映するにはアプリを再起動してください")
                  .font(.caption)
                  .foregroundColor(.orange)
              }
            }
          }
        }
        .formStyle(.grouped)

        Spacer()

        HStack {
          Spacer()
          Button("完了") {
            dismiss()
          }
          .buttonStyle(.borderedProminent)
        }
        .padding()
      }
      .frame(minWidth: 400, minHeight: 300)
    }
  }
#endif

#Preview {
  SettingsView()
}
