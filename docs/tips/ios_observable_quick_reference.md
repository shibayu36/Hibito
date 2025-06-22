# iOS Observation (`@Observable`) 入門

## 目的
最新の Observation フレームワークで導入された `@Observable` マクロの使い方を、AI が読み取りやすい Markdown 形式でまとめる。旧来の `ObservableObject/@Published` からの移行ポイントも含む。

---

## 特徴
- `@Observable` マクロを付けるだけで依存プロパティを自動追跡
- 読み取られたプロパティだけが再描画対象 → オーバードロー削減
- Combine の `Publisher` を生成しない（必要なら従来方式を併用）
- クラス / 構造体の両方で利用可
- **要件**: iOS 17 / Swift 5.9 以降、`import Observation`

---

## 最小サンプル
```swift
import SwiftUI
import Observation

@Observable
final class CounterModel {
    var count = 0
    func increment() { count += 1 }
}

struct ContentView: View {
    @State private var model = CounterModel()  // ルートは @State

    var body: some View {
        VStack(spacing: 12) {
            Text("Count: \(model.count)")  // 読み取ったプロパティだけ再描画
            Button("Up") { model.increment() }
        }
    }
}
```

### 子ビューに渡す
```swift
struct DetailView: View {
    @Bindable var model: CounterModel   // @Bindable で受け取る

    var body: some View {
        Stepper("Count: \(model.count)", value: $model.count)
    }
}
```

---

## 既存コードからの移行手順
1. **宣言を置換**  
   `class Foo: ObservableObject` → `@Observable class Foo`
2. **`@Published` を削除**  
   マクロが自動追跡するため不要
3. **View 側を整理**  
   - ルート View: `@State` でモデルを保持  
   - 子ビュー: `@Bindable` で受け渡し
4. **Combine 依存部分を検討**  
   - Combine が必要なら `ObservableObject` を残す or ラッパーを作る

---

## ObservableObject との主な違い
- **宣言コスト**  
  - `@Observable` はマクロ 1 行のみ  
  - `ObservableObject` はプロトコル + 各プロパティに `@Published`
- **更新通知範囲**  
  - `@Observable`: プロパティ単位  
  - `ObservableObject`: 型単位（一括通知）
- **再描画コスト**  
  - 部分再描画でパフォーマンス向上
- **Combine 連携**  
  - 生成なし（`objectWillChange` もなし）

---

## テストのポイント
- 値オブジェクトとしてそのままテスト可能
- UI 再描画の回数を検証したい場合は `withObservationTracking(_:_:)` を使用

```swift
import XCTest
import Observation

final class CounterTests: XCTestCase {
    func testIncrement() {
        let model = CounterModel()
        XCTAssertEqual(model.count, 0)
        model.increment()
        XCTAssertEqual(model.count, 1)
    }
}
```

---

## よくある落とし穴
- `@Observable` だけでは **Binding 化されない** → 子側は `@Bindable` または `$model.property`
- マルチスレッド更新は `@MainActor` か `MainActor.assumeIsolated()` で UI スレッド保証
- iOS 16 以下をサポートする場合は条件付きコンパイルで従来方式にフォールバック

---

## 補足 Tips
- **Environment 共有**: `ContentView().environment(model)` で下層すべてに注入
- **デバッグ**: Xcode で "Observation Debug Gauges" を有効にすると依存関係を可視化
- **パフォーマンス測定**: Instruments → SwiftUI → Timeline で再描画範囲を確認可能

---

## 参考リンク
- Apple 公式ドキュメント: <https://developer.apple.com/documentation/swiftui/observation>
- WWDC23 "Observable: the next generation" セッション動画

