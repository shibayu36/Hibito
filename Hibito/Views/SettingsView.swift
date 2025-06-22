import SwiftUI

struct SettingsView: View {
  @ObservedObject var settingsViewModel: SettingsViewModel
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        Text("毎日のリセット時刻")
          .font(.headline)
          .padding(.top, 20)

        Picker("リセット時刻", selection: $settingsViewModel.resetHour) {
          ForEach(0..<24) { hour in
            Text("\(hour)時").tag(hour)
          }
        }
        .pickerStyle(.wheel)
        .frame(height: 150)

        Text("タスクは毎日\(settingsViewModel.resetHour)時に自動的に削除されます")
          .font(.caption)
          .foregroundColor(.secondary)

        Spacer()
      }
      .padding()
      .navigationTitle("設定")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("完了") {
            dismiss()
          }
        }
      }
    }
  }
}
