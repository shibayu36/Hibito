# Technology Stack

## Architecture

**MVVM + Repository Pattern (Hybrid)**:
- View層（SwiftUI）、ViewModel層（`@Observable`）、Repository層（SwiftData）の責務分離
- 既存コードはハイブリッド構成で、新機能からRepositoryパターンを適用
- テスタビリティを最初から考慮した設計

## Core Technologies

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData（`@Model`マクロ）
- **iCloud Sync**: CloudKit integration via SwiftData
- **Analytics**: Firebase Analytics
- **Testing**: Swift Testing（`@Test`マクロ）
- **Platform**: iOS 18.5+, macOS 14.0+

## Key Libraries

- **Firebase**: アプリアナリティクス用
- **SwiftData**: データ永続化とiCloud同期
- **Swift Testing**: テストフレームワーク

## Development Standards

### Type Safety
- Swift strict mode使用
- Swiftの強力な型システムを活用

### Code Quality
- `swift format`によるコードフォーマット（pre-commit hook設定済み）
- コメントは必要最小限（公開API、背景情報、複雑なロジックのみ）

### Testing
- **TDDアプローチ**: t-wadaのRed-Green-Refactorサイクル
- **テスト粒度**: 重要なロジックに集中、トリビアルなロジックは対象外
- **Mock判断**: シンプルなRepositoryはin-memory SwiftDataを優先、外部API依存のみMock使用
- **日本語によるテスト表現**: `@Test`で意図を明確に

### SwiftUI/SwiftData実装の注意点

**@MainActor必須**:
- SwiftDataアクセスするRepository層、ViewModel層、テスト層すべてに`@MainActor`が必要

**リアルタイムUI更新**:
- `@Observable`でのUI更新にはStored Property使用（Computed Propertyは検知されない）
- ViewModelにローカル状態を持ち、`didSet`でRepository更新

## Development Environment

### Required Tools
- Xcode 16+
- swift format
- XcodeBuildMCP（自動動作確認用）

### Common Commands
```bash
# Build (iOS Simulator)
xcodebuild -scheme Hibito -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 16' build

# Test (via XcodeBuildMCP)
mcp__XcodeBuildMCP__test_sim_name_proj({
  projectPath: "Hibito.xcodeproj",
  scheme: "Hibito",
  simulatorName: "iPhone 16"
})

# Format
swift format -i --recursive .

# Lint
swift format lint --recursive .
```

## Key Technical Decisions

### YAGNI原則とシンプルさ重視
- 今必要ない機能は実装しない
- エッジケースは認識した上で対応しない判断も重要
- 複雑な実装の前に「本当に必要か？」を問い直す

### 段階的な改善
- 一度にすべてを理想的な設計にしない
- 新機能から新しいパターンを適用
- ハイブリッドアプローチ（新機能はRepository、既存は直接アクセスでも可）

### iCloud同期対応
- 将来のiCloud同期を考慮してSwiftData採用
- CloudKitイベント通知を監視してUI自動更新

### 実装前調査の重視
- 大規模変更では実装前に詳細調査を実施
- 具体的な問題箇所を特定し、段階的実装計画を策定

---
_Document standards and patterns, not every dependency_
