# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

Hibitoは「今日のやる気を上げるためだけのTODOアプリ」です。毎日0時に全タスクが自動的に消去されるという独自のコンセプトを持つiOS/macOSアプリケーションです。

## 開発時の注意
機能開発を行ったら必ず

- xcodebuildを使ったiOS Simulator向けビルドでエラーが出ていないか確認
- 関係するテストを実行

を行って。

## プロジェクト構成の更新について

このプロジェクトは初期開発フェーズのため、ディレクトリ構造やアーキテクチャが頻繁に変更される可能性があります。

### 構成変更時の対応
プロジェクト構成に以下のような変更があった場合は、必ずCLAUDE.mdの該当箇所を更新すること：

1. **ディレクトリ構造の変更**
   - 新しいディレクトリの追加/削除
   - ファイルの移動や名前変更
   - 「プロジェクト構造」セクションを最新の状態に更新

2. **アーキテクチャの変更**
   - デザインパターンの変更（例：MVVM、MVPなど）
   - 新しいManagerやServiceクラスの追加
   - データフローの変更

3. **依存関係の変更**
   - 新しいライブラリの追加
   - Swift Packageの追加/削除

4. **機能の実装状況の変更**
   - 新機能の実装完了
   - 既存機能の削除や大幅な変更

### 更新時の確認手順
1. `ls`や`find`コマンドで現在のディレクトリ構造を確認
2. 主要なSwiftファイルの内容を確認して役割を理解
3. CLAUDE.mdの構造説明と実際の構造の差分を特定
4. 必要な箇所を更新

## リファクタリング時の注意事項

### 不要コードの積極的削除
**⚠️ 重要**: 技術負債の蓄積を防ぐため、不要になったコードは積極的に削除する

#### 基本原則
- **「念のため残す」を避ける**: 使われていないコードを「後で使うかも」という理由で残さない
- **完全な削除**: 関連するファイル、テスト、ドキュメントもセットで削除
- **技術負債の予防**: 古いバグのある実装や非推奨パターンは即座に除去

#### 削除対象の判断基準
1. **使用箇所の調査**: `grep`や`Task`ツールで実際の利用箇所がないことを確認
2. **バグのある実装**: 修正済みの古い実装は残さない
3. **非推奨パターン**: 新しいアーキテクチャに移行済みの古いパターン
4. **重複コード**: 同じ機能を持つ複数の実装がある場合

#### 削除の手順
1. **影響範囲の調査**: 削除対象のコード、テスト、ドキュメントをすべて特定
2. **段階的削除**: ファイル → テストファイル → 空ディレクトリ → ドキュメント更新の順で実行
3. **動作確認**: ビルドとテスト実行で問題がないことを確認
4. **ドキュメント更新**: プロジェクト構造や設計書に変更を反映

#### 例：完全なコード削除
```swift
// ❌ 悪い例：古い実装を残してしまう
func oldBuggyMethod() { ... }  // バグがあるが「念のため」残す
func newCorrectMethod() { ... }  // 修正済み実装

// ✅ 良い例：完全に削除
// 1. oldBuggyMethod() の利用箇所をすべて newCorrectMethod() に変更
// 2. oldBuggyMethod を削除
// 3. 関連テストも削除
// 4. ドキュメント更新
func newCorrectMethod() { ... }
```

### 関数の置き換え時の手順
関数を新しい実装に置き換える場合は、以下の手順を必ず実行すること：

1. **利用箇所の調査**: 置き換え対象の関数のすべての利用箇所を`grep`や`Task`ツールで調査
2. **完全な置き換え**: すべての利用箇所を新しい関数に書き換え
3. **古い関数の削除**: 利用箇所がなくなったことを確認後、古い関数を削除
4. **後方互換性の排除**: 不要な関数を「念のため」残さない

### 例
```swift
// ❌ 悪い例：古い関数を残してしまう
func oldFunction() { ... }  // Deprecated - 残さない！
func newFunction() { ... }

// ✅ 良い例：完全に置き換える
// 1. すべての oldFunction() の呼び出しを newFunction() に変更
// 2. oldFunction を削除
func newFunction() { ... }
```

## 開発コマンド

### ビルドと実行
```bash
# Xcodeでプロジェクトを開く
open Hibito.xcodeproj

# Xcodeでのビルド: Cmd+B
# Xcodeでの実行: Cmd+R

# iPhone 16シミュレータ向けビルド（コマンドライン）
xcodebuild -scheme Hibito -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### テスト
Swift Testingフレームワーク（`@Test`マクロ）を使用しています。XcodeBuildMCPを使ってテストを実行します。

```javascript
// 全テスト実行
mcp__XcodeBuildMCP__test_sim_name_proj({
  projectPath: "Hibito.xcodeproj",
  scheme: "Hibito",
  simulatorName: "iPhone 16"
})

// 特定のテストクラス全体を実行
mcp__XcodeBuildMCP__test_sim_name_proj({
  projectPath: "Hibito.xcodeproj",
  scheme: "Hibito",
  simulatorName: "iPhone 16",
  extraArgs: ["-only-testing", "HibitoTests/SettingsViewModelTests"]
})

// 特定のテストメソッドのみ実行（Swift Testing対応）
mcp__XcodeBuildMCP__test_sim_name_proj({
  projectPath: "Hibito.xcodeproj",
  scheme: "Hibito",
  simulatorName: "iPhone 16",
  extraArgs: ["-only-testing", "HibitoTests/SettingsViewModelTests/testResetTimeUpdate"]
})

// 複数のテストクラスを指定
mcp__XcodeBuildMCP__test_sim_name_proj({
  projectPath: "Hibito.xcodeproj",
  scheme: "Hibito",
  simulatorName: "iPhone 16",
  extraArgs: [
    "-only-testing", "HibitoTests/SettingsViewModelTests",
    "-only-testing", "HibitoTests/SettingsRepositoryTests"
  ]
})

// シミュレータUUID指定（高速化）
mcp__XcodeBuildMCP__test_sim_id_proj({
  projectPath: "Hibito.xcodeproj",
  scheme: "Hibito",
  simulatorId: "98BDEC2F-67E8-4EE3-8024-AFF532E1E42F",
  extraArgs: ["-only-testing", "HibitoTests/SettingsViewModelTests"]
})
```

### コードフォーマット
```bash
# コードフォーマット（プロジェクト全体）
swift format -i --recursive .

# コードlint（プロジェクト全体）
swift format lint --recursive .
```

### 自動動作確認（iOS Simulator）
このプロジェクトではXcodeBuildMCPを導入しているため、機能に関わる変更を加えたときはMCPサーバーを経由して動作確認すること。

## 設計・実装方針

### 設計の基本原則

#### シンプルさを重視
- **YAGNI原則**：「You Aren't Gonna Need It」- 今必要ない機能は実装しない
- **エッジケースの割り切り**：発生確率が極めて低いケースは、認識した上で対応しない判断も重要
- **複雑さを避ける**：例）複雑な監視機構より都度取得の方がシンプルで理解しやすい
- **実装の必要性を問い直す**：複雑な実装をする前に「本当に必要か？」と自問する

#### 段階的な改善
- **完璧主義を避ける**：一度にすべてを理想的な設計にする必要はない
- **新機能から新パターンを適用**：既存コードは動作するなら、新機能から新しいパターンを導入
- **ハイブリッドアプローチ**：例）新機能はRepositoryパターン、既存機能は直接アクセスでも良い

#### 技術選択の判断基準
- **既存システムとの統一性**：新しい技術より、既存の仕組みとの整合性を優先
- **将来の拡張性を考慮**：ただし、過度に将来を心配しない（例：iCloud同期を考慮してSwiftData採用）
- **実用性を重視**：教科書的な実装より、チームや既存コードとの整合性

### アーキテクチャ設計
- **テスタビリティを最初から考慮**：ViewModelパターンの採用、依存性注入の活用
- **責務分離**：View、ViewModel、Repository/Modelの役割を明確に分ける
- **データフローのシンプルさ**：複雑な状態管理より、明確で予測可能なデータフロー

#### レイヤーの責務分離
- **ユーティリティ層の純粋性**：Date拡張などのユーティリティは汎用的に保ち、ドメイン知識を含めない
- **ドメイン知識の適切な配置**：アプリ固有の概念は適切な層（Repository、ViewModel）に配置
- **命名による設計確認**：メソッド名やクラス名で責務の不整合に気づく仕組み

#### 外部インターフェース設計の原則
- **内部実装の完全な隠蔽**：privateメソッドで内部実装を隠し、必要最小限のAPIのみ公開
- **API設計の最小化**：「何を隠すか」も「何を見せるか」と同じくらい重要
- **利用者視点でのインターフェース**：内部の実装詳細ではなく、利用者が必要とする操作を基準にAPI設計
- **実装レベルのコードレビュー観点**：
  - 責務を説明するコメントの適切な配置
  - publicメソッドには簡潔なコメント、privateメソッドは必要に応じて
  - メソッド配置順序（public → private）
  - 無駄な変数代入の回避

#### コメントの適切な使い分け
**⚠️ 重要**: コメントは必要最小限に抑え、コードを見てすぐに分かることはコメント化しない

**コメントを書く場合の限定ケース**:
1. **公開APIの説明**: publicメソッドなどを説明するドキュメントとして
2. **背景情報の補足**: コード内容に表れていない背景がある場合
3. **複雑なロジックの説明**: 複雑なコードでやりたいことの理解が難しく、説明が必要な場合
4. **大規模コードのセクション分け**: 100行以上のコードで、セクション分けをした上で説明を書きたい場合

**例**:
```swift
// ❌ 不要なコメント（コードを見れば分かる）
var resetTime: Int = 0 {
    didSet {
        // ローカル状態の変更をRepositoryに反映
        repository.updateResetTime(resetTime)
    }
}

// ✅ 適切なコメント（背景情報）
var resetTime: Int = 0 {
    didSet {
        // UIレスポンシブ性のためにローカル状態とRepository状態を同期
        repository.updateResetTime(resetTime)
    }
}
```

#### 設計レビューの観点
1. **命名の妥当性**：なぜその名前なのか、役割は明確か
2. **テスタビリティ**：単体テストが書きやすいか、依存関係は注入可能か
3. **拡張性と現実性のバランス**：将来的な機能追加に対応できるが、過度に複雑でないか
4. **既存コードとの一貫性**：既存のパターンに合致するか
5. **エラーハンドリング**：適切なフォールバックがあるか

### SwiftUI/SwiftData実装の重要な注意点

#### SwiftDataアクセスには@MainActorが必須
**⚠️ 極めて重要**: SwiftDataを使用するすべてのクラスには@MainActorが必要

**基本ルール**:
- **Repository層**: SwiftDataに直接アクセスするクラスには必ず`@MainActor`を付ける
- **ViewModel層**: Repository層を呼び出すViewModelにも`@MainActor`が必要
- **テスト層**: Repository/ViewModelをテストするテストクラスにも`@MainActor`が必要

**実装例**:
```swift
// ✅ 正しい実装
@MainActor
class SettingsRepository {
    private let modelContext: ModelContext
    // SwiftDataアクセス処理...
}

@Observable
@MainActor
class SettingsViewModel {
    private let settingsRepository: SettingsRepository
    // ViewModelロジック...
}

@MainActor
struct SettingsRepositoryTests {
    // テストケース...
}
```

**よくある間違い**:
```swift
// ❌ @MainActorがないとランタイムクラッシュ
class SettingsRepository {  // @MainActorが無い！
    private let modelContext: ModelContext
    func getSettings() -> Settings {
        // クラッシュの原因
        try? modelContext.fetch(descriptor).first
    }
}
```

**依存関係の伝播**:
SwiftData → Repository → ViewModel → View の順で@MainActorが伝播する。どこか一箇所でも抜けると、コンパイルエラーまたはランタイムクラッシュが発生する。

#### @ObservableViewModelでのリアルタイムUI更新
**⚠️ 重要**: @ObservableパターンでのUIリアルタイム更新には適切なプロパティ設計が必要

**Stored Property vs Computed Propertyの使い分け**:
- **Stored Property**: @ObservableによるUI更新が正しく動作する
- **Computed Property**: SwiftUIがプロパティ変更を検知できず、UI更新が行われない場合がある

**実装例**:
```swift
@Observable
@MainActor
class SettingsViewModel {
    private let repository: SettingsRepository
    
    // ✅ リアルタイム更新対応: Stored Property + didSet
    var resetTime: Int = 0 {
        didSet {
            repository.updateResetTime(resetTime)
        }
    }
    
    // ❌ UI更新されない: Computed Property
    var resetTime: Int {
        get { repository.getResetTime() }
        set { repository.updateResetTime(newValue) }
    }
    
    init(repository: SettingsRepository) {
        self.repository = repository
        self.resetTime = repository.getResetTime()
    }
}
```

**設計のポイント**:
- **UIレスポンシブ性とデータ整合性の両立**: ViewModelにローカル状態を持ちつつ、didSetでRepository更新を自動実行
- **初期化時の同期**: ViewModelの初期化時にRepositoryから現在値をローカル状態に読み込み
- **二重状態管理の受容**: UIの応答性を保つためにはViewModel層とRepository層での状態の二重管理が必要な場合がある

## 開発フロー

### TDDアプローチ
プロジェクトではt-wadaのTDDアプローチを採用し、テスト駆動開発を実践する：

#### Red-Green-Refactorサイクル
- **Red**: 最初に失敗するテストを書く
- **Green**: テストが通る最小限の実装を行う
- **Refactor**: コードを改善し、テストが通り続けることを確認

#### テスト実装の指針
- **1ステップ1テスト**：特定のロジック実装とテストを1セットにして細かくステップ分け
- **テストの粒度**：基本ケース→エッジケース→統合テストの段階的アプローチ
- **テスト要否の判断**：@Modelクラスなどただのデータコンテナはテスト不要

#### テスト粒度の具体的な判断基準
- **内部がシンプルなら最小限のテスト**：複雑でないロジックに対して過剰なテストは避ける
- **効果的なテストの選択**：多数のテストより、重要な動作を確認する効果的なテストを優先
- **メンテナンスコストの考慮**：過剰なテストは逆にメンテナンスコストを上げるため、必要最小限に抑える
- **ユーザーフローを意識したテスト設計**：
  - update → get → update → getのような実際の使用パターンを反映
  - 単純な単体テストではなく、「ユーザーが実際にやりそうな操作」をテスト
  - 複数の操作の組み合わせでの動作確認

#### テストの除外判断基準
- **UI表示内容のテスト不要**：文字列フォーマットや表示メッセージは実際のUIで確認する
- **トリビアルなロジックは対象外**：単純な文字列結合や基本的な計算処理
- **フレームワークが保証する部分**：SwiftUIのバインディングやSwiftDataの基本操作
- **重要なロジックに集中**：データの取得・更新、ビジネスロジック、状態変更に絞る
- **メンテナンスコストとの天秤**：テストが複雑になりすぎる場合は書かない判断も重要

**例：不要なテスト**
```swift
// ❌ 文字列フォーマットのテスト（UIで確認すれば十分）
#expect(viewModel.resetTimeDescription() == "毎日6:00に...")

// ✅ 重要なロジックのテスト
#expect(viewModel.resetTime == 6) // データの取得・設定
```

#### Mock実装の判断基準
- **シンプルなRepository**: Mockより in-memory SwiftDataを優先
  - 実際のデータフローをテストできる
  - モック作成・メンテナンスコストを避けられる
  - SwiftDataの設定や操作も含めて動作確認できる
- **外部API依存**: Mockが必要（ネットワーク、ファイルシステムなど）
- **複雑な依存関係**: Mockで分離テストが有効
- **パフォーマンステスト**: 実際の処理時間を測りたい場合はMock不要

**判断フロー**
1. 依存先がシンプルか？ → Yes: in-memory/実際のオブジェクト使用
2. 外部システムに依存するか？ → Yes: Mock使用
3. テストが複雑になるか？ → Yes: Mockで分離
4. 作成コスト > テスト価値か？ → Yes: Mock不使用

#### テストの表現力
- **テストメソッド名は仕様**：テストメソッド名で何をテストしているかを明確に表現
- **日本語による意図の明確化**：日本語を使うことでテストの意図を分かりやすく
- **@Suiteによる構造化**：関連するテストをグループ化して関連性を示す

### 実装フロー
#### 開発順序の基本方針
1. **既存コードの理解**：新しい機能を追加する前に、既存のアーキテクチャパターンを理解する
2. **プロトタイプファースト**：まずUIの動きを確認してから本実装に入る
3. **実装優先順位**：UIプロトタイプ→データ基盤→ロジック→統合の順番で進める
4. **段階的な実装**：大きな機能は小さなステップに分けて実装し、各段階で動作確認

#### 実装時の注意事項
- **設計段階でのコード例**：メソッドシグネチャと役割の明確化に重点を置く。実装の詳細は実装段階で検討
- **テスト設計の同時検討**：実装コードと一緒にテストコードの構想も立てる
- **不要な設定は削る**：シンプルさを保つため、必要最小限の実装に留める

## プロジェクト管理

### コミットとドキュメント管理
#### コミットメッセージの方針
- **端的に記述**：「〜を確認」などの動作確認の詳細は不要
- **何をやったかを説明**：実装内容や変更点を明確に記述
- **Phase完了ごとにコミット**：大きな機能は小さなフェーズに分けて管理

#### ドキュメント更新の原則
- **Phase完了ごとに更新**：実装状況をリアルタイムで記録
- **実装計画の文書化**：要件定義と実装計画を一緒に管理して全体像を把握しやすくする
- **学びの蓄積**：実装過程で得た知見をCLAUDE.mdに反映

## アーキテクチャとコード構造

### プロジェクト構造
```
Hibito/
├── HibitoApp.swift          # アプリエントリーポイント、SwiftDataコンテナ設定
├── ModelContainerManager.swift  # SwiftDataコンテナの管理
├── Models/
│   ├── Settings.swift      # 設定データモデル
│   └── TodoItem.swift      # TODOアイテムデータモデル
├── Repositories/
│   └── SettingsRepository.swift # 設定データのSwiftDataアクセス層
├── ViewModels/
│   ├── TodoListViewModel.swift # メインViewのViewModel
│   └── SettingsViewModel.swift # 設定画面のViewModel
├── Views/
│   ├── TodoListView.swift  # メインUI（SwiftUI）
│   ├── SettingsView.swift  # 設定画面
│   └── DebugMenuView.swift # デバッグメニュー（DEBUG環境のみ）
└── Info.plist              # アプリ設定ファイル
```

### テスト構造
```
HibitoTests/
├── Repositories/
│   └── SettingsRepositoryTests.swift # SettingsRepository.swiftのテスト
└── ViewModels/
    ├── TodoListViewModelTests.swift # TodoListViewModel.swiftのテスト
    └── SettingsViewModelTests.swift # SettingsViewModel.swiftのテスト
```

### 主要な技術スタック
- **UI**: SwiftUI
- **データモデル**: SwiftData（`@Model`マクロ）
- **データアクセス**: ViewModelパターン + Repositoryパターンのハイブリッド構成
- **最小OS**: iOS 18.5+, macOS 14.0+
- **コードフォーマット**: swift format（pre-commit hook設定済み）


### 注意事項
- ViewModelパターンを採用（TodoListViewModel）
- ModelContainerManagerによりSwiftDataコンテナを管理
- デバッグメニューはDEBUG環境でのみ表示される
- テストファイルは本体のディレクトリ構造に合わせて整理されている

## Webサイト（Cloudflare Pages）

### 概要
プロジェクトのWebサイトはCloudflare PagesでホスティングされGitHub連携により自動デプロイされています。

### ディレクトリ構造
```
public/
├── _headers          # セキュリティヘッダー設定
├── index.html        # ランディングページ
├── style.css         # スタイルシート
├── privacy.html      # プライバシーポリシー（英語版）
└── privacy_ja.html   # プライバシーポリシー（日本語版）
```

### デプロイ
- GitHubリポジトリとCloudflare Pagesが連携済み
- `public/`ディレクトリの内容が自動的にデプロイされる
- プッシュ時に自動デプロイが実行される
