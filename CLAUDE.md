# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

Hibitoは「今日のやる気を上げるためだけのTODOアプリ」です。毎日0時に全タスクが自動的に消去されるという独自のコンセプトを持つiOS/macOSアプリケーションです。

## 開発時の注意
機能開発を行ったら必ず

- xcodebuildを使ったiOS Simulator向けビルドでエラーが出ていないか確認
- 関係するテストを実行

を行って。

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

## アーキテクチャとコード構造

### プロジェクト構造
```
Hibito/
├── HibitoApp.swift          # アプリエントリーポイント、SwiftDataコンテナ設定
├── Extensions/
│   └── Date+Extensions.swift   # 日付判定用の拡張機能
├── Models/
│   └── TodoItem.swift      # @Modelマクロ使用のデータモデル
├── Services/
│   └── AutoResetService.swift  # 日次リセット機能
├── Utilities/
│   └── OrderingUtility.swift   # タスクの並び替え用ユーティリティ
├── Views/
│   ├── TodoListView.swift  # メインUI（SwiftUI）、データの直接操作
│   └── DebugMenuView.swift # デバッグメニュー（DEBUG環境のみ）
├── ViewModels/             # 空（未使用）
└── Managers/               # 空（未使用）
```

### テスト構造
```
HibitoTests/
├── Extensions/
│   └── Date+ExtensionsTests.swift  # Date+Extensions.swiftのテスト
├── Services/
│   └── AutoResetServiceTests.swift # AutoResetService.swiftのテスト
├── Utilities/
│   └── OrderingUtilityTests.swift  # OrderingUtility.swiftのテスト
└── HibitoTests.swift       # 基本テスト
```

### 主要な技術スタック
- **UI**: SwiftUI
- **データモデル**: SwiftData（`@Model`マクロ）
- **データアクセス**: `@Query`と`@Environment(\.modelContext)`を使用
- **最小OS**: iOS 18.5+, macOS 14.0+
- **コードフォーマット**: swift format（pre-commit hook設定済み）

### 現在の実装状況

#### 実装済み
- TODOリストの基本機能（追加、編集、削除、完了切り替え）
- ドラッグ&ドロップによる並び替え
- ダブルタップでのインライン編集
- **データ永続化**（SwiftDataによる永続化実装済み）
- **日次リセット機能**（AutoResetServiceで0時に自動リセット）
- デバッグメニュー（手動リセット、タスク生成機能）
- ソフトウェアキーボード関連の改善
  - 改行追加時にキーボードが閉じない
  - TextFieldとキーボード間の適切な間隔
  - コンテンツタップでキーボードを閉じる

#### 未実装の重要機能
1. **同期機能**: CloudKit統合によるデバイス間同期

### 注意事項
- `Item.swift`は未使用のため、将来削除予定
- TodoListViewが直接SwiftDataとやり取りしており、ViewModelは使用していない
- デバッグメニューはDEBUG環境でのみ表示される
- テストファイルは本体のディレクトリ構造に合わせて整理されている
