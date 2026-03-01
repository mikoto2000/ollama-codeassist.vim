# ollama-codeassist.vim

Vim からローカル Ollama (`/api/generate`) に非同期リクエストを送り、現在バッファの前後文脈を使ってコード補完候補を生成するプラグインです。

## 現在の実装状態

- メイン実装: `autoload/ollama_codeassist.vim`
- Vital の `Web.AsyncHTTP` で POST リクエストを送信
- エクスポート関数: `ollama_codeassist#Request()`
- 現在カーソル位置を基準に prefix/suffix を作って FIM 形式で問い合わせ
- 返ってきた `response` を現在行へ反映（行の置換/追記）

注: ユーザーコマンド (`:OllamaCodeAssist`) や自動補完 (`completefunc`/`omnifunc`) 連携はまだ未実装です。

## 要件

- Vim9 script が使える Vim
- ローカルで Ollama が起動していること
  - 既定 endpoint: `http://localhost:11434/api/generate`
- 使用モデルがローカルに存在すること
  - 既定: `qwen2.5-coder:14b`

## インストール

`pack` 管理の例:

```vim
" ~/.vimrc or init.vim
packadd ollama-codeassist.vim
```

## 使い方

最小例（手動実行）:

```vim
" キーマップ例
nnoremap <silent> <leader>oa :call ollama_codeassist#Request()<CR>
inoremap <silent> <C-g> :call ollama_codeassist#Request()<CR>
```

実行すると、現在バッファの内容とカーソル位置から context を作成して Ollama に送信し、返答をバッファへ反映します。

## 設定

以下の `g:` 変数で接続先とモデルを変更できます。

```vim
let g:ollama_codeassist_host = 'localhost'
let g:ollama_codeassist_port = 11434
let g:ollama_codeassist_path = '/api/generate'
let g:ollama_codeassist_model = 'qwen2.5-coder:14b'
```

## トラブルシュート

- 応答が返らない:
  - Ollama が起動しているか確認
  - `host`/`port`/`path` を確認
- モデルエラー:
  - `ollama list` に `g:ollama_codeassist_model` が存在するか確認
- Vim 側で変化がない:
  - `:messages` を確認
  - 非同期通信に必要な実行環境（`curl`/`python` など）が利用可能か確認

## 制約

- バッファ反映ロジックはシンプルで、編集内容の安全性チェックは最小限です
- エラーハンドリングは限定的です
- 応答品質はモデル/プロンプトに依存します
