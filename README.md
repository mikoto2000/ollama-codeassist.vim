# ollama-codeassist.vim

`ollama-codeassist.vim` は、Vim からローカル Ollama (`/api/generate`) に非同期リクエストを送り、コード補完候補を行うプラグインです。

## 現状

- メイン実装: `autoload/ollama-codeassist.vim`
- Vital の `Web.AsyncHTTP` を使って POST リクエストを送信
- 現在はサンプル `Context` を使い、ファイル読込時に `RequestInner(context)` を実行する構成
- コマンド・マッピング・自動補完連携は未実装

## 要件

- Vim9 script が使える Vim または Neovim
- Ollama がローカル起動していること
  - 既定エンドポイント: `http://localhost:11434/api/generate`
- 使用モデルがローカルに存在すること
  - 既定: `qwen2.5:14b-instruct`

## インストール

`pack` 管理の場合の例:

```vim
" ~/.vimrc or init.vim
packadd ollama-codeassist.vim
```

または、このリポジトリを `runtimepath` に含めて読み込んでください。

## 実行の流れ

現状は `autoload/ollama-codeassist.vim` が読み込まれると、以下を実行します。

1. サンプルバッファ内容と行番号からプロンプトを組み立てる
2. Ollama `/api/generate` に JSON を POST する
3. レスポンスの `response` を `echomsg` で表示する

結果は `:messages` で確認できます。

## 設定を変える場所

`autoload/ollama-codeassist.vim` の先頭付近を編集します。

- `host` / `port` / `endpoint_path`
- `data_template.model`
- `prompt_template`

## 制約

- 現在の実装はデモ寄りで、実バッファ連携・挿入処理は入っていません
- 文字コードが環境依存で崩れる場合があります
- エラー処理は最小限です（HTTP ステータスを表示）

## トラブルシュート

- `status` が `200` 以外:
  - Ollama が起動しているか確認
  - `host` / `port` / `endpoint_path` を確認
- モデルエラー:
  - `data_template.model` のモデルが `ollama list` に存在するか確認
- 何も表示されない:
  - `:messages` を確認
  - 非同期通信に必要な外部コマンド (`curl` など) が利用可能か確認

## 今後の実装候補

- ユーザーコマンド化（例: `:OllamaCodeAssist`）
- カーソル位置と現在バッファを使った動的コンテキスト生成
- 補完メニュー連携（`completefunc` / `omnifunc`）
- 設定を `g:` 変数で外出し
