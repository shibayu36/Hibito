# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

Hibitoは「今日のやる気を上げるためだけのTODOアプリ」です。毎日0時に全タスクが自動的に消去されるという独自のコンセプトを持つiOS/macOSアプリケーションです。

## 開発コマンド

### ビルドと実行
```bash
# Xcodeでプロジェクトを開く
open Hibito.xcodeproj

# Xcodeでのビルド: Cmd+B
# Xcodeでの実行: Cmd+R
```

### テスト
現在テストは未実装ですが、Swift Testingフレームワーク（`@Test`マクロ）を使用する予定です。

## アーキテクチャとコード構造

### MVVMパターン
```
Hibito/
├── HibitoApp.swift          # アプリエントリーポイント、SwiftDataコンテナ設定
├── ContentView.swift        # メインUI（SwiftUI）
├── Models/
│   └── TodoItem.swift      # @Modelマクロ使用のデータモデル
└── ViewModels/
    └── TodoViewModel.swift  # @Observableマクロ使用のビューモデル
```

### 主要な技術スタック
- **UI**: SwiftUI
- **データモデル**: SwiftData（`@Model`マクロ）
- **状態管理**: `@Observable`マクロ
- **最小OS**: iOS 18.5+, macOS 14.0+

### 現在の実装状況

#### 実装済み
- TODOリストの基本機能（追加、編集、削除、完了切り替え）
- ドラッグ&ドロップによる並び替え
- ダブルタップでのインライン編集

#### 未実装の重要機能
1. **データ永続化**: TodoItemモデルはSwiftData対応だが、ModelContainerに未登録
2. **日次リセット**: 0時の自動リセット機能が未実装
3. **同期機能**: CloudKit統合によるデバイス間同期
4. **通知**: リセット前の通知機能

### 注意事項
- `Item.swift`は未使用のため、将来削除予定
- 現在の実装はメモリ内のみで動作し、アプリ再起動でデータが失われる
- SwiftDataの完全な統合には`HibitoApp.swift`でTodoItemをModelContainerに追加する必要がある