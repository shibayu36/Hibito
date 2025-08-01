# PRP: iCloud同期機能実装

## 概要
HibitoアプリにiCloud同期機能を追加する実装計画です。ユーザーは設定画面でiCloud同期のON/OFFを切り替えでき、複数デバイス間でTODOが自動同期されます。

## 調査結果サマリー

### 技術的な重要ポイント
1. **SwiftData CloudKit統合**:
   - ModelConfigurationで`cloudKitDatabase: .automatic`または`.none`を設定
   - 全モデルプロパティはオプショナルまたはデフォルト値が必須
   - `@Attribute(.unique)`はCloudKitで使用不可
   - 同期はシーンフェーズ変更時にトリガー（リアルタイムではない）

2. **同期タイミング** (iOS 18以降):
   - ローカル→CloudKit: `modelContext.save()`後10-60秒以内
   - CloudKit→ローカル: サイレントPush受信時即座に反映
   - オフライン時はキューに保持、接続復帰後に自動送信
   - フォアグラウンド復帰時にまとめてフェッチ

3. **制限事項**:
   - 強制同期APIは存在しない
   - ModelContainerは後から切替不可（再生成が必要）
   - レイテンシ前提のUX設計が必要（数十秒〜数分）

## 実装設計図

### Phase 1: Settings モデルの更新
**ファイル**: `Hibito/Models/Settings.swift`

```swift
@Model
class Settings {
  var resetTime: Int
  var iCloudEnabled: Bool  // 新規プロパティ
  
  init(resetTime: Int = 0, iCloudEnabled: Bool = false) {
    self.resetTime = resetTime
    self.iCloudEnabled = iCloudEnabled
  }
}
```

### Phase 2: SettingsRepository の更新
**ファイル**: `Hibito/Repositories/SettingsRepository.swift`

```swift
/// iCloud同期設定を取得
func getICloudEnabled() -> Bool {
    return getSettings().iCloudEnabled
}

/// iCloud同期設定を更新
func updateICloudEnabled(_ enabled: Bool) {
    let settings = getSettings()
    settings.iCloudEnabled = enabled
    try? modelContext.save()
}
```

### Phase 3: ModelContainerManager の動的対応
**ファイル**: `Hibito/ModelContainerManager.swift`

```swift
import Foundation
import SwiftData
import Combine

class ModelContainerManager: ObservableObject {
  static let shared = ModelContainerManager()
  
  @Published private(set) var modelContainer: ModelContainer
  private var isCloudEnabled: Bool = false
  
  private init() {
    // 初期化時は設定を読み込んでコンテナを作成
    let tempContainer = Self.createLocalContainer()
    let tempContext = ModelContext(tempContainer)
    let tempRepo = SettingsRepository(modelContext: tempContext)
    let cloudEnabled = tempRepo.getICloudEnabled()
    
    self.modelContainer = Self.createContainer(cloudEnabled: cloudEnabled)
    self.isCloudEnabled = cloudEnabled
  }
  
  @MainActor
  func reconfigureForCloudSync(_ enabled: Bool) {
    guard isCloudEnabled != enabled else { return }
    
    // 新しいコンテナを作成
    modelContainer = Self.createContainer(cloudEnabled: enabled)
    isCloudEnabled = enabled
  }
  
  private static func createContainer(cloudEnabled: Bool) -> ModelContainer {
    let schema = Schema([TodoItem.self, Settings.self])
    
    let configuration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: false,
      cloudKitDatabase: cloudEnabled ? .automatic : .none
    )
    
    do {
      return try ModelContainer(for: schema, configurations: [configuration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }
  
  private static func createLocalContainer() -> ModelContainer {
    // 設定読み込み専用のローカルコンテナ
    return createContainer(cloudEnabled: false)
  }
  
  @MainActor
  var mainContext: ModelContext {
    modelContainer.mainContext
  }
}
```

### Phase 4: SettingsViewModel の更新
**ファイル**: `Hibito/ViewModels/SettingsViewModel.swift`

```swift
@Observable
@MainActor
class SettingsViewModel {
  private let settingsRepository: SettingsRepository
  weak var containerManager: ModelContainerManager?
  
  var resetTime: Int = 0 {
    didSet {
      settingsRepository.updateResetTime(resetTime)
    }
  }
  
  var iCloudEnabled: Bool = false {
    didSet {
      settingsRepository.updateICloudEnabled(iCloudEnabled)
      // コンテナ再構成をトリガー
      containerManager?.reconfigureForCloudSync(iCloudEnabled)
    }
  }
  
  init(settingsRepository: SettingsRepository, containerManager: ModelContainerManager? = nil) {
    self.settingsRepository = settingsRepository
    self.containerManager = containerManager
    self.resetTime = settingsRepository.getResetTime()
    self.iCloudEnabled = settingsRepository.getICloudEnabled()
  }
}
```

### Phase 5: SettingsView の更新
**ファイル**: `Hibito/Views/SettingsView.swift`

```swift
struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var containerManager: ModelContainerManager
  @State private var viewModel: SettingsViewModel
  
  init() {
    let repo = SettingsRepository(modelContext: ModelContainerManager.shared.mainContext)
    _viewModel = State(initialValue: SettingsViewModel(
      settingsRepository: repo,
      containerManager: ModelContainerManager.shared
    ))
  }
  
  var body: some View {
    NavigationStack {
      Form {
        // 既存のリセット時間設定セクション
        
        Section {
          Toggle("iCloud同期", isOn: $viewModel.iCloudEnabled)
        } header: {
          Text("同期設定")
        } footer: {
          Text("複数のデバイス間でタスクを自動的に同期します。変更は数十秒〜数分で反映されます。")
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
```

### Phase 6: TodoListViewModel の同期対応
**ファイル**: `Hibito/ViewModels/TodoListViewModel.swift`

ModelContext.didSave通知を購読して自動更新を実装：

```swift
import Combine

@Observable
@MainActor
class TodoListViewModel {
  // 既存のプロパティ
  private var cancellables = Set<AnyCancellable>()
  
  init(modelContext: ModelContext, dateProvider: DateProvider) {
    // 既存の初期化処理
    
    // CloudKit同期の通知を購読
    NotificationCenter.default.publisher(for: ModelContext.didSave)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.refreshTodoItems()
      }
      .store(in: &cancellables)
  }
  
  // 既存のrefreshTodoItemsメソッドを活用
}
```

### Phase 7: HibitoApp の更新
**ファイル**: `Hibito/HibitoApp.swift`

```swift
@main
struct HibitoApp: App {
  @StateObject private var containerManager = ModelContainerManager.shared
  @Environment(\.scenePhase) private var scenePhase
  
  var body: some Scene {
    WindowGroup {
      TodoListView()
        .modelContainer(containerManager.modelContainer)
        .environmentObject(containerManager)
        .onChange(of: scenePhase) { _, newPhase in
          if newPhase == .active {
            // フォアグラウンド復帰時の同期トリガー
            // SwiftDataが自動的に処理
          }
        }
    }
  }
}
```

### Phase 8: Xcodeプロジェクト設定
1. **Capabilities追加**:
   - iCloud → CloudKitを有効化
   - Background Modes → Remote notificationsを有効化
   
2. **Info.plist更新**:
   ```xml
   <key>NSUbiquitousContainers</key>
   <dict>
       <key>iCloud.$(PRODUCT_BUNDLE_IDENTIFIER)</key>
       <dict>
           <key>NSUbiquitousContainerIsDocumentScopePublic</key>
           <false/>
           <key>NSUbiquitousContainerSupportedFolderLevels</key>
           <string>Any</string>
       </dict>
   </dict>
   ```

## テスト戦略

### ユニットテスト
1. **SettingsRepositoryTests**: iCloudEnabledプロパティの永続化テスト
2. **SettingsViewModelTests**: トグル動作とコンテナ再構成のテスト
3. **ModelContainerManagerTests**: CloudKit設定切り替えロジックのテスト

### 手動テストチェックリスト
1. [ ] 設定画面でiCloud同期をON/OFF切り替え
2. [ ] デバイスAでTODO作成
3. [ ] デバイスBでアプリ起動、1分以内にTODO表示確認
4. [ ] オフラインでTODO作成・編集
5. [ ] ネットワーク復帰後の同期確認
6. [ ] バックグラウンド→フォアグラウンドでの同期確認

## エラーハンドリング

1. **CloudKitエラー**: ログのみ（ユーザーには表示しない）
2. **マイグレーション失敗**: ローカルストレージにフォールバック
3. **ネットワークエラー**: 変更をキューに保持、後で自動同期

## 実装タスク

1. [ ] Settings モデルにiCloudEnabledプロパティ追加
2. [ ] SettingsRepositoryにiCloud設定メソッド実装
3. [ ] ModelContainerManagerを動的切り替え対応に改修
4. [ ] SettingsViewModelにトグルロジック実装
5. [ ] SettingsViewにiCloudトグルUI追加
6. [ ] TodoListViewModelに同期通知購読追加
7. [ ] HibitoAppでコンテナ管理更新
8. [ ] XcodeでCloudKit Capabilities設定
9. [ ] ユニットテスト作成
10. [ ] 複数デバイスでの手動テスト実施

## 検証ゲート

```bash
# iOS Simulatorビルド
xcodebuild -scheme Hibito -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build

# テスト実行
mcp__XcodeBuildMCP__test_sim_name_proj({
  projectPath: "Hibito.xcodeproj",
  scheme: "Hibito",
  simulatorName: "iPhone 16"
})
```

## 成功指標
- iCloudトグルがクラッシュなく動作
- デバイス間でデータが1分以内に同期
- オフラインモードが継続動作
- ユーザーに同期通知を表示しない
- 全テストがパス

## 信頼度スコア: 9/10

技術メモの詳細な情報により、実装パスが明確です。1点減点の理由：
- 実際のCloudKit同期動作は実機でのみ完全にテスト可能