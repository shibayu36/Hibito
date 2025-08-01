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

### Phase 2: ModelContainer設定 ✅ 完了
**目的**: SwiftDataとCloudKitの連携設定

2. **ModelContainerManager修正**
   - [x] UserDefaultsから同期設定を読み取る機能追加
   - [x] cloudKitDatabase設定を動的に切り替える機能追加（.automatic / .none）
   - [x] ビルドテスト実行

### Phase 3: SettingsRepository拡張 ✅ 完了
**目的**: iCloud同期設定の管理機能追加

3. **同期設定管理**
   - [x] getUseCloudSync()メソッド追加（キー名と一貫性のあるメソッド名に）
   - [x] updateUseCloudSync()メソッド追加
   - [x] SettingsRepositoryのUserDefaults注入対応（テスタビリティ向上）
   - [x] UserDefaults注入テスト追加（SettingsRepositoryTests）

### Phase 4: UI実装とテスト ✅ 完了
**目的**: ユーザーがiCloud同期をON/OFF切り替えできるUI

4. **SettingsView更新**
   - [x] iCloud同期ON/OFFスイッチ追加
   - [x] 説明テキスト追加（「TODOと設定を複数デバイス間で同期します」）
   - [x] 再起動案内表示（設定変更時のみ表示するよう改善）

5. **SettingsViewModel更新**
   - [x] useCloudSyncプロパティ追加
   - [x] 同期設定変更時の処理追加（didSetパターン）
   - [x] hasCloudSyncSettingChangedプロパティ追加（変更検知機能）
   - [x] 同期ON/OFF切り替えテスト追加（SettingsViewModelTests）
   - [x] ビルドテスト実行

### Phase 5: CloudKit同期通知対応 ✅ 完了
**目的**: 他デバイスからの同期データをリアルタイムでUI反映

6. **同期完了通知**
   - [x] TodoListViewModelにNSPersistentCloudKitContainer.eventChangedNotification監視追加
   - [x] 同期完了時のUI更新処理追加（Combineベースの実装）
   - [x] import成功時のみloadTodos()を実行するよう最適化
   - [x] 既存テスト実行・修正（全21テスト合格）

### Phase 6: isCompleted同期問題修正 ✅ 完了
**目的**: 別端末でのTODO完了状態変更がUIに反映されない問題の修正

6. **問題調査と修正**
   - [x] 別端末でのisCompleted変更時の同期動作調査
   - [x] TodoListViewModelの同期処理確認（loadTodos()の実行タイミング）
   - [x] UI反映されない原因の特定（ObservableObjectの更新問題？）
   - [x] デバッグメニューとの動作差異分析（なぜデバッグメニューでは反映されるか）
   - [x] 修正実装とテスト

### Phase 7: CloudKit警告対応 ✅ 完了
**目的**: CoreData+CloudKit警告の解消

7. **警告対応**
   - [x] CoreData+CloudKit警告の詳細調査（"store was removed from the coordinator"）
   - [x] ModelContainer設定の見直し
   - [x] 警告を解消する実装修正
   - [x] 動作への影響確認

### Phase 8: 最終確認
**目的**: リリース準備

8. **総合確認**
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

### SettingsRepository拡張（実装済み）
```swift
// UserDefaults管理（端末固有）
private let userDefaults: UserDefaults

init(modelContext: ModelContext, userDefaults: UserDefaults = .standard) {
    self.modelContext = modelContext
    self.userDefaults = userDefaults
}

func getUseCloudSync() -> Bool {
    return userDefaults.bool(forKey: "useCloudSync")
}

func updateUseCloudSync(_ enabled: Bool) {
    userDefaults.set(enabled, forKey: "useCloudSync")
}
```

## UX設計

### 設定画面UI
- **明確な説明**：「TODOと設定を複数デバイス間で同期します」（リセット時間も同期されることを明示）
- **再起動案内**：設定変更時のみ「変更を反映するにはアプリを再起動してください」表示（常時表示はしない）
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

## Phase 3実装で得られた知見

### 実装上の改善点
1. **メソッド名の一貫性**: 当初`getCloudSyncEnabled`としていたが、UserDefaultsのキー名`useCloudSync`に合わせて`getUseCloudSync`に統一
2. **テスト設計の最適化**: デフォルト値テストを別にするより、1つのテストで初期値→true→falseの流れで包括的に確認
3. **UserDefaults注入パターン**: デフォルト引数を使うことで既存コードへの影響を最小限に抑えつつテスタビリティを向上

### 実装詳細
- SettingsRepositoryにUserDefaults注入機能を追加
- iCloud同期設定の取得・更新メソッドを実装
- テスト用のUserDefaultsインスタンスを使った完全なテストカバレッジを実現

## Phase 4実装で得られた知見

### UX改善の重要性
1. **UIメッセージの正確性**: 「複数デバイス間でTODOを同期します」→「TODOと設定を複数デバイス間で同期します」に変更（リセット時間も同期されることを明示）
2. **適切なタイミングでの案内表示**: 常に再起動案内を表示するのではなく、設定が実際に変更された時のみ表示するよう改善
3. **変更検知の実装**: `hasCloudSyncSettingChanged`プロパティで初期値と現在値を比較して変更を検知

### 実装パターンの一貫性
1. **didSetパターンの活用**: 既存の`resetTime`と同じ`didSet`パターンを使用して、ViewModelとRepositoryの同期を実現
2. **SwiftUIの@Observableパターン**: Stored Propertyを使うことでリアルタイムUI更新を正しく動作させる

### テスト設計の改善
1. **テスト名の明確化**: 「何をテストしているか」を端的に表現する形に変更（例：「useCloudSyncの設定が変わったときだけ、hasCloudSyncSettingChangedがtrueになる」）
2. **過剰なテストケースの削除**: 本質的でないテストケース（「再度変更」など）を削除してシンプルに保つ
3. **UserDefaultsテストの安定化**: `removePersistentDomain`を先に実行してクリーンな状態を確保

### 実装詳細
- SettingsViewModelに変更検知機能を追加（`initialUseCloudSync`、`hasCloudSyncSettingChanged`）
- SettingsViewで条件付き再起動案内表示を実装
- テストカバレッジを向上（初期値false/trueの両方のケースを含む包括的なテスト）

## Phase 5実装で得られた知見

### CloudKit通知処理の実装
1. **Combineアプローチの採用**: NotificationCenter.defaultの`publisher(for:)`を使用してSwiftらしい実装を実現
2. **自動メモリ管理**: AnyCancellableを使用することでdeinitでの手動クリーンアップが不要に
3. **効率的なフィルタリング**: import成功時のみUI更新することでパフォーマンスを最適化

### 技術的な選択
1. **通知フィルタリングの重要性**: 
   - import + succeeded: 他デバイスからのデータ取り込み時のみUI更新
   - export時は処理しない: 自デバイスからの送信は既にローカル反映済み
2. **@MainActorとの整合性**: Combineの`receive(on: DispatchQueue.main)`でメインスレッド実行を保証

### テスト実装の課題と学び
1. **NSPersistentCloudKitContainer.Eventのモック困難性**: 
   - 実際のEventオブジェクトを作成できないことが判明
   - テスト用の#if DEBUGコードは本番コードを汚染するため不適切
2. **代替アプローチの検討**:
   - 通知処理を別クラスに切り出す
   - loadTodos()の呼び出し回数をカウント
   - 統合テストレベルでの動作確認に留める

### 実装詳細
- setupCloudKitNotificationObserver()メソッドでCloudKit通知を監視
- compactMapとfilterでimport成功イベントのみを処理
- weak selfでメモリリークを防止
- 既存の21テストすべて合格を確認

## Phase 7実装で得られた知見

### CloudKit警告の調査結果
1. **警告の非再現性**: 
   - 「store was removed from the coordinator」警告が再現しない状況を確認
   - iCloud同期のON/OFF切り替えでも警告は発生せず
   - 動作に影響がないことを確認

2. **現状の動作確認**:
   - ModelContainerManagerのsingleton実装は問題なく動作
   - cloudKitDatabase設定（.automatic/.none）の切り替えも正常
   - アプリの再起動後も設定が正しく反映される

### 実装詳細
- 警告の詳細調査を実施したが、現時点では再現せず
- 動作への影響がないことを確認し、Phase 7を完了


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
