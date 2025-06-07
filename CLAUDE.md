# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## プロジェクト概要

HibitoはiOS/macOS向けのSwiftプロジェクトで、現在は初期セットアップ段階にあります。リポジトリにはXcode/Swift開発用の.gitignoreファイルが設定されていますが、まだSwiftプロジェクトファイルやソースコードは含まれていません。

## プロジェクトの現状

初期コミット時点で、このリポジトリには以下が含まれています：
- プロジェクト名のみが記載されたREADME.md
- iOS/macOS Swift開発用に設定された.gitignore

Xcode特有の.gitignore設定から、このプロジェクトはiOS/macOS開発を目的としていることがわかりますが、Xcodeプロジェクト、Swift Package Manager設定、ソースファイルはまだ作成されていません。

## 開発環境

.gitignoreファイルから、このプロジェクトは以下の使用を想定しています：
- 開発環境：Xcode
- プログラミング言語：Swift
- 依存関係管理：Swift Package Manager、CocoaPods、またはCarthageの可能性
- 自動化ツール：fastlaneの可能性

## 今後の作業

このリポジトリで作業する際は、以下が必要になる可能性があります：
1. XcodeプロジェクトまたはSwiftパッケージの作成
2. iOS/macOS開発に適したプロジェクト構造の設定
3. 依存関係管理（SPM、CocoaPods、またはCarthage）の設定
4. プロジェクトセットアップ後のビルド、テスト、リントコマンドの確立