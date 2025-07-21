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

## 実装TODOリスト

### Phase 1: PoC実装（動作確認優先）
**目的**: 理論と実践のギャップ確認、早期リスク発見、動作する最小実装

1. **プロジェクト設定**
   - [ ] Xcode Capabilities追加（CloudKit）
   - [ ] Entitlements更新（CloudKit権限追加）

2. **最小限実装**
   - [ ] UserDefaultsベースのiCloud同期ON/OFF切り替えUI追加
   - [ ] ModelContainerManager修正（.automatic使用、UserDefaults参照）

3. **動作確認**
   - [ ] iOS Simulatorビルド、基本機能テスト
   - [ ] 複数デバイス間での同期テスト実行

### Phase 2: アーキテクチャ整理
**目的**: PoCから綺麗な設計への移行

4. **データ層整理**
   - [ ] Settings.swiftからuseCloudSync削除
   - [ ] SettingsRepository拡張（UserDefaults注入対応）
   - [ ] SettingsViewModel修正（Repository経由のUserDefaults操作）

5. **品質確保**
   - [ ] 既存テスト実行・修正

### Phase 3: UI改善
**目的**: ユーザー体験の向上

6. **設定画面改善**
   - [ ] 設定画面の同期スイッチUI改善（説明テキスト、再起動案内）
   - [ ] 再起動促進アラート実装

### Phase 4: 同期UI更新
**目的**: CloudKitとの連携強化

7. **自動更新機能**
   - [ ] TodoListViewModelにModelContext.didSave通知追加
   - [ ] CloudKit同期完了時の自動UI更新確認

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

### ModelContainer起動時設定
```swift
@MainActor
init() {
    let schema = Schema([TodoItem.self, Settings.self])
    
    // UserDefaultsから同期設定を取得
    let useCloudSync = UserDefaults.standard.bool(forKey: "useCloudSync")
    
    let config = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false,
        cloudKitDatabase: useCloudSync ? .automatic : .none  // .automatic使用
    )
    
    self.modelContainer = try! ModelContainer(for: schema, configurations: [config])
}
```

### SettingsRepository設計
```swift
@MainActor
class SettingsRepository {
    private let modelContext: ModelContext
    private let userDefaults: UserDefaults
    
    init(modelContext: ModelContext, userDefaults: UserDefaults = .standard) {
        self.modelContext = modelContext
        self.userDefaults = userDefaults
    }
    
    // SwiftData管理（同期対象）
    func getResetTime() -> Int { ... }
    func updateResetTime(_ time: Int) { ... }
    
    // UserDefaults管理（端末固有）
    func getCloudSyncEnabled() -> Bool {
        return userDefaults.bool(forKey: "useCloudSync")
    }
    
    func updateCloudSyncEnabled(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: "useCloudSync")
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
