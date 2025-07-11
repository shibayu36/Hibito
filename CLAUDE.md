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
Swift Testingフレームワーク（`@Test`マクロ）を使用しています。

```bash
# 全テスト実行
xcodebuild test -scheme Hibito -destination 'platform=iOS Simulator,name=iPhone 16'

# 特定のテスト関数を実行
xcodebuild test -scheme Hibito -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HibitoTests/Extensions/Date+ExtensionsTests/testIsBeforeToday
```

swift testは使えないから、xcodebuild testを使うこと。

### コードフォーマット
```bash
# コードフォーマット（プロジェクト全体）
swift format -i --recursive .

# コードlint（プロジェクト全体）
swift format lint --recursive .
```

### 自動動作確認（iOS Simulator）
このプロジェクトではXcodeBuildMCPを導入しているため、機能に関わる変更を加えたときはMCPサーバーを経由して動作確認すること。

## 設計・実装時の注意事項

### 設計の基本方針

#### シンプルさを重視
- **YAGNI原則**：「You Aren't Gonna Need It」- 今必要ない機能は実装しない
- **エッジケースの割り切り**：発生確率が極めて低いケースは、認識した上で対応しない判断も重要
- **複雑さを避ける**：例）複雑な監視機構より都度取得の方がシンプルで理解しやすい

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

#### 設計レビューの観点
1. **命名の妥当性**：なぜその名前なのか、役割は明確か
2. **テスタビリティ**：単体テストが書きやすいか、依存関係は注入可能か
3. **拡張性と現実性のバランス**：将来的な機能追加に対応できるが、過度に複雑でないか
4. **既存コードとの一貫性**：既存のパターンに合致するか
5. **エラーハンドリング**：適切なフォールバックがあるか

### 実装プロセス
- **既存コードの理解**：新しい機能を追加する前に、既存のアーキテクチャパターンを理解する
- **設計段階でのコード例**：メソッドシグネチャと役割の明確化に重点を置く。実装の詳細は実装段階で検討
- **テスト設計の同時検討**：実装コードと一緒にテストコードの構想も立てる
- **段階的な実装**：大きな機能は小さなステップに分けて実装し、各段階で動作確認

## アーキテクチャとコード構造

### プロジェクト構造
```
Hibito/
├── HibitoApp.swift          # アプリエントリーポイント、SwiftDataコンテナ設定
├── ModelContainerManager.swift  # SwiftDataコンテナの管理
├── Extensions/
│   └── Date+Extensions.swift   # 日付判定用の拡張機能
├── Models/
│   └── TodoItem.swift      # @Modelマクロ使用のデータモデル
├── ViewModels/
│   └── TodoListViewModel.swift # メインViewのViewModel
├── Views/
│   ├── TodoListView.swift  # メインUI（SwiftUI）
│   └── DebugMenuView.swift # デバッグメニュー（DEBUG環境のみ）
└── Info.plist              # アプリ設定ファイル
```

### テスト構造
```
HibitoTests/
├── Extensions/
│   └── Date+ExtensionsTests.swift  # Date+Extensions.swiftのテスト
└── ViewModels/
    └── TodoListViewModelTests.swift # TodoListViewModel.swiftのテスト
```

### 主要な技術スタック
- **UI**: SwiftUI
- **データモデル**: SwiftData（`@Model`マクロ）
- **データアクセス**: ViewModelパターンでModelContextを経由
- **最小OS**: iOS 18.5+, macOS 14.0+
- **コードフォーマット**: swift format（pre-commit hook設定済み）

### 現在の実装状況

#### 実装済み
- TODOリストの基本機能（追加、編集、削除、完了切り替え）
- ドラッグ&ドロップによる並び替え
- ダブルタップでのインライン編集
- **データ永続化**（SwiftDataによる永続化実装済み）
- ViewModelパターンによるデータ管理
- デバッグメニュー（手動リセット、タスク生成機能）
- ソフトウェアキーボード関連の改善
  - 改行追加時にキーボードが閉じない
  - TextFieldとキーボード間の適切な間隔
  - コンテンツタップでキーボードを閉じる

#### 未実装の重要機能
1. **日次リセット機能**: 0時に全タスクを自動的に消去する機能
2. **同期機能**: CloudKit統合によるデバイス間同期

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
