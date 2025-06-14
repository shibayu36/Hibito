# iCloud同期実装設計書
作成日: 2025-06-12

## 現状分析

### 現在の実装状況
- ローカルでのみ動作するTODOリスト
- SwiftDataの`@Model`は定義済みだが、ModelContainerに未登録
- CloudKitのエンタイトルメントは設定済みだが、iCloudコンテナ識別子が未設定
- TodoViewModelで配列として順序を管理

### 問題点
1. TodoItemが個別のモデルとして存在し、順序情報を持たない
2. TodoViewModel内での配列管理がSwiftDataと同期できない
3. 順序の永続化とiCloud同期時の順序保持が困難

## 推奨アーキテクチャ

### データモデル設計

#### Option 1: TodoListモデルを追加（推奨）
```swift
@Model
class TodoList {
    var id = UUID()
    var createdAt = Date()
    var items: [TodoItem] = []
    var lastResetDate: Date?
    
    init() {}
}

@Model
class TodoItem {
    var id = UUID()
    var content: String = ""
    var isCompleted = false
    var list: TodoList? // 親リストへの参照
    
    init(content: String = "", isCompleted: Bool = false) {
        self.content = content
        self.isCompleted = isCompleted
    }
}
```

**メリット:**
- 配列の順序がそのまま保存される
- CloudKit同期で1つのエンティティとして管理可能
- 日次リセットがTodoList全体の削除・再作成で済む
- 将来の「明日のリスト」機能への拡張が容易

#### Option 2: TodoItemに順序プロパティを追加
```swift
@Model
class TodoItem {
    var id = UUID()
    var content: String = ""
    var isCompleted = false
    var sortOrder: Int
    var createdAt: Date
}
```

**デメリット:**
- 並び替え時に複数のアイテムのsortOrder更新が必要
- 同期時の競合解決が複雑

#### Option 3: 双方向リンクリスト構造
```swift
@Model
class TodoItem {
    var id = UUID()
    var content: String = ""
    var isCompleted = false
    var next: TodoItem?
    var previous: TodoItem?
}
```

**デメリット:**
- 実装が複雑
- CloudKit同期時のリレーション管理が困難

## 実装計画

### フェーズ1: データモデルの再構築

1. **TodoList.swiftの新規作成**
   ```swift
   import Foundation
   import SwiftData
   
   @Model
   class TodoList {
       var id = UUID()
       var createdAt = Date()
       @Relationship(deleteRule: .cascade) var items: [TodoItem] = []
       
       init() {}
   }
   ```

2. **TodoItem.swiftの更新**
   - 親リストへの参照を追加
   - Relationshipの設定

3. **HibitoApp.swiftの更新**
   ```swift
   let schema = Schema([
       TodoList.self,
       TodoItem.self
   ])
   let modelConfiguration = ModelConfiguration(
       schema: schema,
       isStoredInMemoryOnly: false,
       cloudKitDatabase: .automatic
   )
   ```

### フェーズ2: ViewModelとUIの更新

1. **ContentViewでの@Query使用**
   ```swift
   @Query private var todoLists: [TodoList]
   @Environment(\.modelContext) private var modelContext
   
   var todaysList: TodoList? {
       todoLists.first { list in
           Calendar.current.isDateInToday(list.createdAt)
       }
   }
   ```

2. **TodoViewModelの役割変更**
   - データ管理をSwiftDataに委譲
   - UIロジックのみを担当
   - または完全に廃止してViewに統合

### フェーズ3: iCloud設定

1. **Xcodeプロジェクト設定**
   - Signing & CapabilitiesでCloudKitを有効化
   - iCloudコンテナ識別子を設定（例: `iCloud.com.yourcompany.Hibito`）

2. **エンタイトルメントの更新**
   ```xml
   <key>com.apple.developer.icloud-container-identifiers</key>
   <array>
       <string>iCloud.com.yourcompany.Hibito</string>
   </array>
   ```

### フェーズ4: 日次リセット機能

1. **リセットロジック**
   - AppDelegateまたはSceneDelegate実装
   - バックグラウンドタスクの設定
   - 0時に古いTodoListを削除、新規作成

2. **同期考慮事項**
   - タイムゾーンの違いを考慮
   - 各デバイスのローカル時刻でリセット

### フェーズ5: テストと最適化

1. **同期テスト**
   - 複数デバイスでの動作確認
   - 順序保持の確認
   - オフライン時の動作確認

2. **パフォーマンス最適化**
   - 大量アイテム時の同期速度
   - バッチ処理の実装

## 技術的考慮事項

### CloudKit制限事項
- レコードサイズ: 1MB以下
- リレーション: CKReferenceで管理
- 同期レイテンシ: 通常1-3秒

### SwiftData + CloudKit統合
- 自動的なオフライン対応
- 競合解決（最終更新優先）
- バックグラウンド同期

### セキュリティ
- エンドツーエンド暗号化
- ユーザーのiCloudアカウントに紐づく
- プライバシー保護

## リスクと対策

1. **データ移行**
   - 既存ユーザーのデータ移行スクリプト
   - または新規インストール扱い

2. **同期競合**
   - 楽観的ロックで対応
   - ユーザーに競合解決UIは提供しない

3. **ストレージ容量**
   - 日次リセットで自動的に管理
   - 古いデータは自動削除

## まとめ

TodoListモデルを導入することで、順序を保持したままiCloud同期が可能になります。SwiftDataとCloudKitの統合により、最小限のコードで堅牢な同期機能を実現できます。