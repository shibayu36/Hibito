# order値をtimeIntervalSince1970ベースに変更する設計

## 概要
現在のTodoItemのorder値は連番（max+1）方式を採用しているが、iCloud同期時に重複が発生し順序が不定になる問題がある。この問題を解決するため、order値をtimeIntervalSince1970ベースに変更する。

## 現在の問題

### 問題の詳細
- **現在の実装**: `maxOrder + 1.0`による連番方式
- **問題**: 複数デバイスで同時にタスク作成時、同じorder値が生成される
- **影響**: iCloud同期後に順序が不定になる

### 具体的なシナリオ
```
デバイスA: maxOrder = 4.0 → 新規作成 order = 5.0
同時刻にデバイスB: maxOrder = 4.0 → 新規作成 order = 5.0
iCloud同期後: 同じorder値の2つのアイテムが存在 → 順序が不定
```

### 現在のコード
```swift
// TodoListViewModel.swift:38-39
let maxOrder = todos.last?.order ?? 0.0
let newTodo = TodoItem(content: trimmedContent, order: maxOrder + 1.0)
```

## 解決策

### 採用する方式: timeIntervalSince1970ベース
order値を作成時刻の`Date().timeIntervalSince1970`で決定する。

```swift
let newOrder = Date().timeIntervalSince1970
let newTodo = TodoItem(content: trimmedContent, order: newOrder)
```

### 技術的根拠
- **精度**: マイクロ秒精度（例: 1735251234.567890）
- **重複回避**: 人間の操作速度では同じマイクロ秒での作成は不可能
- **自然な順序**: 時系列順で新しいタスクが下に配置される
- **一意性**: 異なる時刻 = 異なるorder値が保証される

### メリット
1. **完全な重複回避**: マイクロ秒精度により実質的に重複不可能
2. **シンプルな実装**: maxOrder計算が不要になり、コードが簡潔に
3. **iCloud同期対応**: デバイス間で一意性が保証される
4. **自然な時系列順序**: 作成時刻順にタスクが並ぶ
5. **将来の並び替え機能との互換性**: Double型をそのまま使用可能

### デメリット
1. **order値の可読性**: 数値が大きくなる（例: 1735251234.567890）
2. **既存データとの互換性**: 既存の1.0, 2.0, 3.0...との混在

## 実装計画

### Phase 1: 新規作成処理の変更
1. `TodoListViewModel.addTodo()`メソッドの修正
2. `DebugMenuView`での新規作成処理の修正
3. 単体テストの更新

### Phase 2: 動作確認
1. 単体テスト実行
2. iOSシミュレータでのビルド確認
3. 順序の動作確認

### 変更対象ファイル
- `Hibito/ViewModels/TodoListViewModel.swift` (line 38-39)
- `Hibito/Views/DebugMenuView.swift` (maxOrder計算箇所)
- `HibitoTests/ViewModels/TodoListViewModelTests.swift` (テストの更新)

## 実装詳細

### 変更前
```swift
func addTodo(content: String) {
    let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedContent.isEmpty else { return }

    let maxOrder = todos.last?.order ?? 0.0
    let newTodo = TodoItem(content: trimmedContent, order: maxOrder + 1.0)
    modelContext.insert(newTodo)

    loadTodos()
}
```

### 変更後
```swift
func addTodo(content: String) {
    let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedContent.isEmpty else { return }

    let newOrder = Date().timeIntervalSince1970
    let newTodo = TodoItem(content: trimmedContent, order: newOrder)
    modelContext.insert(newTodo)

    loadTodos()
}
```

## 互換性について

### 既存データとの混在
- 既存のorder値（1.0, 2.0, 3.0...）と新しいorder値（1735251234.567890...）が混在する
- ソート処理には影響なし（Double型の大小比較で正しく動作）
- 既存データは現在の順序を保持

### 将来の拡張性
- Fractional Ordering: 将来の並び替え機能でも対応可能
- iCloud同期: デバイス間で一意性が保たれる
- スケーラビリティ: 長期間の使用でも問題なし

## リスク分析

### 低リスク
- **同時作成での重複**: マイクロ秒精度により実質的に不可能
- **パフォーマンス**: Date()の生成コストは無視できる程度
- **型の互換性**: 既存のDouble型をそのまま使用

### 中リスク
- **時刻変更**: システム時刻の変更による順序の逆転
  - 対策: 一般的なユースケースでは影響なし
- **タイムゾーン**: 異なるタイムゾーンでの使用
  - 対策: UTCベースなので問題なし

## テスト戦略

### 単体テスト
1. **基本機能**: 新規タスク作成でtimeIntervalSince1970が使用されることを確認
2. **順序保証**: 時系列順にタスクが並ぶことを確認
3. **既存データ互換性**: 既存order値との混在で正しくソートされることを確認

### 統合テスト
1. **iOSシミュレータ**: 実際のUI操作での動作確認
2. **連続作成**: 高速でタスクを連続作成した際の順序確認

## 実装完了の判定基準
1. ✅ 全単体テストがパス
2. ✅ iOSシミュレータでビルド成功
3. ✅ 新規タスク作成時にtimeIntervalSince1970ベースのorder値が設定される
4. ✅ 既存タスクとの混在環境で正しい順序表示
5. ✅ 連続タスク作成で重複しないorder値が生成される