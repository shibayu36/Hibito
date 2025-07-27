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

### Phase 1: プロジェクト設定とCloudKit有効化 ✅ 完了
**目的**: CloudKit同期機能の基盤準備

1. **プロジェクト設定**
   - [x] Xcode Capabilities追加（CloudKit）
   - [x] Entitlements更新（CloudKit権限追加、iCloud.org.shibayu36.dailydo設定）

### Phase 2: ModelContainer設定
**目的**: SwiftDataとCloudKitの連携設定

2. **ModelContainerManager修正**
   - [ ] UserDefaultsから同期設定を読み取る機能追加
   - [ ] cloudKitDatabase設定を動的に切り替える機能追加（.automatic / .none）
   - [ ] ビルドテスト実行

### Phase 3: SettingsRepository拡張
**目的**: iCloud同期設定の管理機能追加

3. **同期設定管理**
   - [ ] getCloudSyncEnabled()メソッド追加
   - [ ] updateCloudSyncEnabled()メソッド追加
   - [ ] SettingsRepositoryのUserDefaults注入対応（テスタビリティ向上）
   - [ ] UserDefaults注入テスト追加（SettingsRepositoryTests）

### Phase 4: UI実装とテスト
**目的**: ユーザーがiCloud同期をON/OFF切り替えできるUI

4. **SettingsView更新**
   - [ ] iCloud同期ON/OFFスイッチ追加
   - [ ] 説明テキスト追加（「複数デバイス間でTODOを同期します」）
   - [ ] 再起動案内表示

5. **SettingsViewModel更新**
   - [ ] useCloudSyncプロパティ追加
   - [ ] 同期設定変更時の処理追加
   - [ ] 同期ON/OFF切り替えテスト追加（SettingsViewModelTests）
   - [ ] ビルドテスト実行

### Phase 5: CloudKit同期通知対応
**目的**: 他デバイスからの同期データをリアルタイムでUI反映

6. **同期完了通知**
   - [ ] TodoListViewModelにNSPersistentCloudKitContainer.eventChangedNotification監視追加
   - [ ] 同期完了時のUI更新処理追加
   - [ ] 既存テスト実行・修正

### Phase 6: 最終確認
**目的**: リリース準備

7. **総合確認**
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

### ModelContainer起動時設定（実装例）
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
    
    do {
        self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}
```

### SettingsRepository拡張（実装例）
```swift
// UserDefaults管理（端末固有）- 追加予定のメソッド
func getCloudSyncEnabled() -> Bool {
    return UserDefaults.standard.bool(forKey: "useCloudSync")
}

func updateCloudSyncEnabled(_ enabled: Bool) {
    UserDefaults.standard.set(enabled, forKey: "useCloudSync")
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
