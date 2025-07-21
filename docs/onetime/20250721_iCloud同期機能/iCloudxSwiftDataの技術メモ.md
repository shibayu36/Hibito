SwiftData × iCloud同期 まとめ

iOS 18 以降 / Swift 5 / Xcode 16

⸻

同期タイミング

ローカル → CloudKit
	•	modelContext.save() でキューに登録
	•	約10–60秒以内にまとめてアップロード
	•	シーンがバックグラウンドへ移行・アプリ終了時にも強制フラッシュ
	•	オフライン時は端末キューに保持し、接続復帰後に自動送信

CloudKit → ローカル
	•	CloudKit が サイレント Push (CKDatabaseSubscription) を送信
	•	受信した瞬間にマージされ UI 更新
	•	Push を受け取れない状況では、フォアグラウンド復帰時にまとめてフェッチ

開発時の要点
	•	Capability
	•	iCloud ▸ CloudKit
	•	Background Modes ▸ Remote Notifications（Push を受け取るため）
	•	force sync API は存在しない → 検証時は save() やシーンのバックグラウンド化でキューを促す
	•	レイテンシ前提で UX を設計（数十秒〜数分）

⸻

iCloud同期 ON / OFF 切替

cloudKitDatabase 値	状態
.automatic / .private("iCloud.com.xxx")	同期 ON
.none	同期 OFF （ローカルのみ）

ModelContainer は後から切替不可
設定変更時は 新しい ModelContainer を生成して UI に差し替える。

@AppStorage("useICloudSync") var useICloudSync = true

@MainActor
func makeContainer(sync: Bool) throws -> ModelContainer {
    let schema = Schema([Memo.self])
    let cfg = ModelConfiguration(
        schema: schema,
        cloudKitDatabase: sync ? .automatic : .none)
    return try ModelContainer(for: schema, configurations: [cfg])
}

Toggle("iCloud 同期", isOn: $useICloudSync)
    .onChange(of: useICloudSync) { newValue in
        Task { container = try await makeContainer(sync: newValue) }
    }

既存レコードは ON→OFF→ON でも保持され、再同期される。
モデルごとに同期可否を分けたい場合は複数の ModelConfiguration を渡す。

⸻

ViewModel へ自動反映する方法

通知を購読
	•	iOS 18 / macOS 15 以降: ModelContext.didSave
	•	iOS 17系: NSManagedObjectContextObjectsDidChange で代替

import Combine
import SwiftData

@Observable
final class MemoListVM {
    private let context: ModelContext
    private var bag = Set<AnyCancellable>()
    @MainActor private(set) var memos: [Memo] = []

    init(context: ModelContext) {
        self.context = context
        reload()

        NotificationCenter.default.publisher(for: ModelContext.didSave)
            .receive(on: MainActor.shared)
            .sink { [weak self] _ in self?.reload() }
            .store(in: &bag)
    }

    @MainActor
    private func reload() {
        let desc = FetchDescriptor<Memo>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        memos = (try? context.fetch(desc)) ?? []
    }
}

差分だけ使いたい場合

note.userInfo[ModelContext.NotificationKey.inserted] などから PersistentIdentifier を取り出し
context.model(for:) で実体を取得して配列に反映する。

注意点
	•	暗黙オートセーブは遅延するため 明示的に context.save() を呼ぶこと
	•	object: を省けば他コンテキストや CloudKit マージ後の保存も拾える（通知数増加に注意）

⸻

チェックリスト
	•	iCloud ▸ CloudKit Capability
	•	Background ▸ Remote Notifications
	•	cloudKitDatabase をユーザー設定で .automatic / .none に切替
	•	設定変更時は ModelContainer 再生成
	•	ViewModel で ModelContext.didSave を購読して UI 更新
	•	レイテンシを考慮した UX（即時性が不要な UI / ローディング表示）

これで SwiftData と iCloud 同期を柔軟に制御しつつ、ViewModel に自動反映できる構成になる。
