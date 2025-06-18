# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

Hibitoは「今日のやる気を上げるためだけのTODOアプリ」です。毎日0時に全タスクが自動的に消去されるという独自のコンセプトを持つiOS/macOSアプリケーションです。

## 開発時の注意
機能開発を行ったら必ず

- xcodebuildを使ったiOS Simulator向けビルドでエラーが出ていないか確認
- 関係するテストを実行

を行って。

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
xcodebuild test -scheme Hibito -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:HibitoTests/DateExtensionsTests/testIsBeforeToday
```

### コードフォーマット
```bash
# コードフォーマット（プロジェクト全体）
swift format -i --recursive .

# コードlint（プロジェクト全体）
swift format lint --recursive .
```

### 自動動作確認（iOS Simulator）
このプロジェクトではios-simulator-mcpを導入しているため、機能に関わる変更を加えたときはMCPサーバーを経由して動作確認すること。

このMCPサーバーを使って操作を加えるときは、必ずui_describe_allで現在の画面の状況を把握すること。

## アーキテクチャとコード構造

### プロジェクト構造
```
Hibito/
├── HibitoApp.swift          # アプリエントリーポイント、SwiftDataコンテナ設定
├── ContentView.swift        # メインUI（SwiftUI）、データの直接操作
├── Models/
│   └── TodoItem.swift      # @Modelマクロ使用のデータモデル
├── Services/
│   └── AutoResetService.swift  # 日次リセット機能
├── Extensions/
│   └── Date+Extensions.swift   # 日付判定用の拡張機能
├── Views/
│   └── DebugMenu.swift     # デバッグメニュー（DEBUG環境のみ）
├── ViewModels/             # 空（未使用）
└── Managers/               # 空（未使用）
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
- ContentViewが直接SwiftDataとやり取りしており、ViewModelは使用していない
- デバッグメニューはDEBUG環境でのみ表示される
