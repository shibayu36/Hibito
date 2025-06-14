# Git Hooks

このディレクトリには、プロジェクトで使用するGit hooksの参考ファイルが含まれています。

## pre-commit

Swiftファイルを自動的にフォーマットするpre-commitフックです。

### セットアップ

```bash
# pre-commitフックをコピー
cp .githooks/pre-commit .git/hooks/pre-commit

# 実行権限を付与
chmod +x .git/hooks/pre-commit
```

### 機能

- ステージングされたSwiftファイルを自動的にフォーマット
- フォーマット後のファイルを自動的に再ステージング
- プロジェクト全体のlintチェック（エラーがある場合はコミットを中止）

### 注意事項

- Xcode内蔵の`swift format`コマンドが必要です（Xcode 16以降）
- コミット時に自動的にコードがフォーマットされるため、意図しない変更が含まれる可能性があります
- 大きなプロジェクトではlintチェックに時間がかかる場合があります