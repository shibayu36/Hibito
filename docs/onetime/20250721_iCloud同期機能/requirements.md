# ユーザーストーリー

ユーザーとして 複数のAppleデバイスを使っている
いつでも 設定画面でiCloud同期をオンに切り替えたい
そうすれば デフォルトでデータがアップロードされず、自分で同期のタイミングを管理できる

ユーザーとして 複数端末間でTODOを扱っている
したいこと ある端末でTODOを追加・編集・削除したら、他の端末をフォアグラウンドにした際に1分以内で反映されていてほしい
そうすれば デバイスをまたいでも作業が途切れずスムーズに続けられる

ユーザーとして オフライン環境（機内モードや地下鉄など）でもアプリを使う
したいこと ネットワークがなくてもTODOを作成・編集できる
そうすれば 接続状況に関係なくタスク管理を続けられる

時間に余裕のないユーザーとして
したいこと 同期はバックグラウンドで自動的に行われ、同期完了の通知や確認ダイアログを見せられたくない
そうすれば 余計な操作や表示に気を取られずタスク処理に集中できる

---

# iCloud同期機能 詳細設計

## 設計の基本方針

### 1. シンプルさを重視した段階的移行
- **既存アーキテクチャ活用**：Repository + ViewModelパターンはそのまま
- **最小限の変更**：ModelConfigurationとUI設定追加が中心
- **後方互換性**：既存データは保持、新機能は追加のみ

### 2. ユーザー体験重視
- **デフォルトOFF**：ユーザーが明示的に選択するまでローカルのみ
- **シンプルな操作**：ON/OFFスイッチのみの直感的操作
- **自動オフライン対応**：CloudKitが自動処理（開発者の追加実装不要）

### 3. 技術的堅牢性
- **CloudKit活用**：オフライン対応、同期タイミングはCloudKitに委任
- **パフォーマンス**：バックグラウンド同期、UI応答性維持
- **テスタビリティ**：既存テストは維持、同期ON/OFF切り替えのみテスト追加

## PoCで得られた知見

### 実装面の発見
1. **CloudKit同期の自動性**: `.automatic`設定で期待通りの自動同期が実現
2. **通知機構の有効性**: `NSPersistentCloudKitContainer.eventChangedNotification`で同期検知可能
3. **明示的save()の必要性**: 一部操作で自動保存されないケースがあり、明示的なsave()が必要
4. **Settings重複問題**: 複数デバイス間で同期した際にSettingsが重複する可能性を発見

### 設計判断の妥当性確認
1. **UserDefaults管理**: SwiftDataに含めずUserDefaultsで管理する判断が正しかった
2. **再起動ベース**: 動的切り替えより再起動ベースの方が安定
3. **最小限の変更**: 既存アーキテクチャを維持したまま同期機能を追加できた

## 実装TODOリスト

### Phase 1: PoC実装（動作確認優先）✅ 完了
**目的**: 理論と実践のギャップ確認、早期リスク発見、動作する最小実装

1. **プロジェクト設定**
   - [x] Xcode Capabilities追加（CloudKit）
   - [x] Entitlements更新（CloudKit権限追加、iCloud.org.shibayu36.dailydo設定）

2. **最小限実装**
   - [x] UserDefaultsベースのiCloud同期ON/OFF切り替えUI追加（SettingsView）
   - [x] ModelContainerManager修正（.automatic使用、UserDefaults参照）
   - [x] SettingsRepositoryに同期設定管理機能追加（getCloudSyncEnabled/updateCloudSyncEnabled）
   - [x] SettingsViewModelにuseCloudSyncプロパティ追加

3. **動作確認**
   - [x] iOS Simulatorビルド、基本機能テスト
   - [ ] 複数デバイス間での同期テスト実行（実機テスト必要）

**PoCで発見した追加実装**:
- TodoListViewModelにNSPersistentCloudKitContainer.eventChangedNotification監視を追加
- 各種操作（追加、削除、移動等）で明示的なsave()呼び出しを追加
- Settings重複排除ロジックを実装（複数件存在時に1件に統合）

### Phase 2: 本実装への移行
**目的**: PoCから本実装への移行、コード品質向上

4. **コード整理**
   - [ ] デバッグ用print文の削除
   - [ ] コメントアウトされたコードの削除
   - [ ] 不要なimport文（CoreData）の削除

5. **品質確保**
   - [ ] 既存テスト実行・修正
   - [ ] SettingsRepositoryのUserDefaults注入対応（テスタビリティ向上）
   - [ ] 同期設定に関するテスト追加

### Phase 3: UI改善
**目的**: ユーザー体験の向上

6. **設定画面改善**
   - [ ] 設定画面の同期スイッチUI改善（説明テキスト、再起動案内）
   - [ ] 再起動促進アラート実装

### Phase 4: 同期UI更新
**目的**: CloudKitとの連携強化

7. **自動更新機能**
   - [ ] ~~TodoListViewModelにModelContext.didSave通知追加~~（PoCで無限ループ問題を発見、不要と判断）
   - [x] NSPersistentCloudKitContainer.eventChangedNotification監視実装（PoCで実装済み）
   - [ ] CloudKit同期完了時の自動UI更新動作確認（実機テスト必要）

### Phase 5: テスト追加
**目的**: 品質と保守性の確保

8. **テスト実装**
   - [ ] UserDefaults注入テスト（SettingsRepositoryTests）
   - [ ] 同期ON/OFF切り替えテスト（SettingsViewModelTests）

### Phase 6: 最終確認
**目的**: リリース準備

9. **総合確認**
   - [ ] iOS Simulator向けビルドエラー確認
   - [ ] 既存機能の動作維持確認
   - [ ] デバイス間同期テスト（1分以内反映）
   - [ ] オフライン時正常動作確認

## 技術仕様詳細

### CloudKit同期の特性（自動処理）
- **ローカル→CloudKit**: `modelContext.save()`で10-60秒以内にアップロード
- **CloudKit→ローカル**: サイレントPushで即座にマージ、UI更新
- **オフライン対応**: CloudKitが端末キューに自動保持、復帰後自動送信
- **開発者の作業**: 通常のSwiftData操作のみ（特別な処理不要）

### データ管理方針

#### SwiftDataモデル（同期対象）
```swift
@Model
class Settings {
    var resetTime: Int      // デバイス間で同期したい設定
    
    init(resetTime: Int = 0) {
        self.resetTime = resetTime
    }
}
```

#### UserDefaults管理（端末固有）
```swift
// 端末ごとの設定（同期対象外）
UserDefaults.standard.bool(forKey: "useCloudSync")  // デフォルト: false
```

### ModelContainer起動時設定（PoCで実装済み）
```swift
private init() {
    let schema = Schema([TodoItem.self, Settings.self])
    
    // UserDefaultsから同期設定を取得
    let useCloudSync = UserDefaults.standard.bool(forKey: "useCloudSync")
    let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        cloudKitDatabase: useCloudSync ? .automatic : .none
    )
    print("🔧 modelConfiguration.cloudKitDatabase: \(modelConfiguration.cloudKitDatabase)")
    
    do {
        self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
```

### SettingsRepository設計（PoCで実装済み）
```swift
@MainActor
class SettingsRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // SwiftData管理（同期対象）
    func getResetTime() -> Int {
        return getSettings().resetTime
    }
    
    func updateResetTime(_ time: Int) {
        let settings = getSettings()
        settings.resetTime = time
        try? modelContext.save()
    }
    
    // UserDefaults管理（端末固有）
    func getCloudSyncEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: "useCloudSync")
    }
    
    func updateCloudSyncEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "useCloudSync")
    }
    
    // Settings重複排除ロジック付き
    private func getSettings() -> Settings {
        let descriptor = FetchDescriptor<Settings>()
        let allSettings = (try? modelContext.fetch(descriptor)) ?? []
        
        if let first = allSettings.first {
            // 2件以上ある場合は重複を削除
            if allSettings.count > 1 {
                allSettings.dropFirst().forEach { modelContext.delete($0) }
                try? modelContext.save()
            }
            return first
        }
        
        let newSettings = Settings(resetTime: 0)
        modelContext.insert(newSettings)
        try? modelContext.save()
        return newSettings
    }
}
```

## UX設計

### 設定画面UI
- **明確な説明**：「複数デバイス間でTODOを同期します」
- **再起動案内**：設定変更時に「変更を反映するにはアプリを再起動してください」表示
- **シンプル**：ON/OFFだけの直感的操作
- **余計な表示なし**：同期状況や通知は一切表示しない

## リスク軽減策

### 既存機能の保護
- **デフォルトOFF**：既存ユーザーに影響なし
- **後方互換性**：既存データは自動マイグレーション
- **CloudKit信頼性**：同期・オフライン処理はAppleが保証
- **安定性重視**：動的Container切り替えを避け、起動時設定で安全性確保

### テスト戦略
- Phase毎のビルド&テスト実行
- 既存テスト維持（SettingsRepositoryTests等）
- 新規テスト追加：
  - UserDefaults注入でテスト分離
  - テスト専用UserDefaults使用
  - 設定値の永続化テスト
- **オフラインテスト不要**：CloudKitが自動処理するため
- **動的切り替えテスト不要**：再起動ベースのシンプルな仕組み

## 実装完了後の確認項目

### 機能確認
- [ ] iCloud同期ON/OFF切り替え
- [ ] デバイス間でのTODO同期（1分以内）
- [ ] オフライン時の正常動作（CloudKit自動処理）
- [ ] 余計な表示がないこと（シンプルなUI）

### 非機能確認
- [ ] 既存機能の動作維持
- [ ] パフォーマンス劣化なし
- [ ] エラー処理の適切性
- [ ] ユーザビリティの向上
