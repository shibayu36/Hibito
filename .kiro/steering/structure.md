# Project Structure

## Organization Philosophy

**レイヤーベース + 責務分離アーキテクチャ**:
- View、ViewModel、Repository/Modelで責務を明確に分ける
- ユーティリティ層は汎用的に保ち、ドメイン知識を含めない
- 内部実装を完全に隠蔽し、必要最小限のAPIのみ公開

## Directory Patterns

### Models (`Hibito/Models/`)
**Purpose**: SwiftDataモデル定義（`@Model`マクロ）
**Example**: `TodoItem.swift`, `Settings.swift`
**Role**: データコンテナとして機能、ビジネスロジックは含めない

### Repositories (`Hibito/Repositories/`)
**Purpose**: SwiftDataアクセス層、ドメインロジックの配置
**Example**: `SettingsRepository.swift`
**Role**: データ取得・更新、ドメイン知識をカプセル化
**Note**: 必ず`@MainActor`を付ける

### ViewModels (`Hibito/ViewModels/`)
**Purpose**: UI状態管理とビジネスロジック
**Example**: `TodoListViewModel.swift`, `SettingsViewModel.swift`
**Pattern**: `@Observable @MainActor class`で実装
**Note**: Stored Property + `didSet`でリアルタイムUI更新

### Views (`Hibito/Views/`)
**Purpose**: SwiftUI UIコンポーネント
**Example**: `TodoListView.swift`, `SettingsView.swift`, `DebugMenuView.swift`
**Role**: UIレンダリングのみ、ロジックはViewModelに委譲

### Providers (`Hibito/Providers/`)
**Purpose**: 時刻取得などの抽象化プロトコル
**Example**: DateProviderプロトコル（予定）
**Role**: テスタビリティ向上のための依存性注入

### Tests (`HibitoTests/`)
**Purpose**: Swift Testingによる自動テスト
**Structure**: 本体のディレクトリ構造に合わせて整理
**Example**: `ViewModels/TodoListViewModelTests.swift`, `Repositories/SettingsRepositoryTests.swift`
**Note**: 必ず`@MainActor`を付ける

### Web (`public/`)
**Purpose**: Cloudflare Pagesでホスティングされる公式Webサイト
**Files**: `index.html`, `privacy.html`, `privacy_ja.html`, `style.css`, `_headers`
**Deployment**: GitHub連携で自動デプロイ

## Naming Conventions

- **Files**: PascalCase（`TodoListView.swift`, `SettingsRepository.swift`）
- **Classes/Structs**: PascalCase
- **Functions/Variables**: camelCase
- **Test Methods**: 日本語で意図を明確化（`@Test("リセット時刻の更新")`）

## Code Organization Principles

### 責務分離の徹底
- **ユーティリティ層の純粋性**: Date拡張などは汎用的に、ドメイン知識を含めない
- **ドメイン知識の適切な配置**: アプリ固有の概念はRepository/ViewModelに
- **命名による設計確認**: メソッド名/クラス名で責務の不整合に気づく

### 外部インターフェース設計
- **privateメソッドで内部実装を隠蔽**: 必要最小限のAPIのみ公開
- **利用者視点でのAPI設計**: 内部実装詳細ではなく、利用者が必要とする操作を基準に
- **コメント配置**: publicメソッドには簡潔なコメント、privateは必要に応じて

### テスタビリティ設計
- **依存性注入**: ViewModelへのRepositoryやDateProviderの注入
- **in-memory SwiftData**: シンプルなRepositoryテストでMockより優先
- **ユーザーフローを意識**: 実際の使用パターンをテスト（update → get → update → get）

### リファクタリング方針
- **不要コードの積極的削除**: 「念のため残す」を避ける、技術負債の予防
- **完全な削除**: 関連ファイル、テスト、ドキュメントもセットで削除
- **段階的削除**: ファイル → テストファイル → 空ディレクトリ → ドキュメント更新

## Project Management

### Commit Strategy
- **端的に記述**: 動作確認の詳細は不要
- **Phase完了ごとにコミット**: 大きな機能は小さなフェーズに分けて管理

### Documentation
- **実装状況をリアルタイムで記録**: Phase完了ごとにCLAUDE.md更新
- **学びの蓄積**: 実装過程で得た知見を文書化

---
_Document patterns, not file trees. New files following patterns shouldn't require updates_
