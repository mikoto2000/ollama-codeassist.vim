vim9script

var host = get(g:, 'ollama_codeassist_host', 'localhost')
var port = get(g:, 'ollama_codeassist_port', 11434)
var path = get(g:, 'ollama_codeassist_path', '/api/generate')
var model = get(g:, 'ollama_codeassist_model', 'qwen2.5-coder:14b')
# qwen2.5:14b-instruct
# codellama:13b

var endpoint_url = $"http://{host}:{port}{path}"

const AsyncHTTP = vital#ollamacodeassist#import("Web.AsyncHTTP")

class Context
  var language: string
  var cursorLine: number
  var prefix: string
  var suffix: string

  def new(language: string, cursorLine: number, prefix: string, suffix: string)
    this.language = language
    this.cursorLine = cursorLine
    this.prefix = prefix
    this.suffix = suffix
  enddef
endclass

const data_template = {
  "model": model,
  "prompt": null,
  "suffix": null,
  "stream": false,
  "options": {
    "stop": ["<|FIM_START|>", "<|FIM_STOP|>", "<|im_start|>", "<|im_end|>"],
  }
}
def UserCb(ctx: Context, response: any)

  if response.status == 200
    # コンテキストの行に、レスポンスの内容を挿入する
    var s = json_decode(response.content).response

    # \n を改行に変換するが、 \\n はそのまま残す（エスケープされた \n と区別す るため）
    s = substitute(s, '\\\\n', "\%x01", 'g')
    s = substitute(s, '\\n', "\%x00", 'g')
    s = substitute(s, "\%x01", '\\n', 'g')

    # もし \u0000 が文字として入ってくる場合も吸収（保険）
    s = substitute(s, '\\u0000', "\%x00", 'g')

    # NUL を改行に変換
    s = substitute(s, "\%x00", "\n", 'g')

    # 改行で行分割して挿入
    var lines = split(s, '\r\?\n', 1)
    setline(ctx.cursorLine, lines[0])
    append(ctx.cursorLine, lines[1 : -1])
  else
    echomsg response
  endif
enddef

# 現在のバッファからコンテキストを作成する関数
def CreateCurrentBufferContext(): Context
  # 現在の行番号を取得
  var line = line('.')

  # 現在のバッファから言語を推測
  var language = ''
  if &filetype != ''
    language = &filetype
  endif

  # バッファ全体の内容を取得
  var buffer_prefix = $"// language: {language}\n" .. $"// Please only codes, and not output codeblock text.\n// Don't add closing brackets if they already exist in suffix.\n" .. join(getline(1, '.'), '\n')
  var buffer_suffix = '<|FIM_STOP|>' .. join(getline('.', '$'), '\n')
  #var buffer_prefix = $"// language: {language}\n" .. $"// Please only codes, and not output codeblock text.\n// Don't add closing brackets if they already exist in suffix.\n" .. join(getregion(getpos('.'), [0, line('$'), col([line('$'), '$']), 0]), "\n")
  #var buffer_suffix = '<|FIM_STOP|>' .. join(getregion(getpos('.'), [0] + searchpos('\%$', 'n')), "\n")

  ## プレフィックス計算(現在の行より前の10行分を取得)
  #var lnum = line('.')
  #var prefix_start_lnum = max([1, line - 10])
  #var prefix_end_lnum = max([1, line - 1])
  #var buffer_prefix = join(getline(prefix_start_lnum, prefix_end_lnum), "\n")

  ## サフィックス計算（現在の行から10行分を取得）
  #var suffix_start_lnum = min([line('$'), lnum + 1])
  #var suffix_end_lnum = min([line('$'), lnum + 10])
  #var buffer_suffix = join(getline(suffix_start_lnum, suffix_end_lnum), "\n")
  #echomsg buffer_suffix

  return Context.new(language, line, buffer_prefix, buffer_suffix)
enddef

# コンテキストを基に、コード補完のリクエストを送る関数
def RequestInner(ctx: Context)
  var data = copy(data_template)
  data.language = ctx.language
  data.cursorLine = ctx.cursorLine
  data.prompt = ctx.prefix
  data.suffix = ctx.suffix

  AsyncHTTP.request({
        \ 'method': 'POST',
        \ 'url': endpoint_url,
        \ 'data': json_encode(data),
        \ 'userCallback': function('UserCb', [ctx]),
        \ })
enddef

export def Request()
  const ctx = CreateCurrentBufferContext()
  RequestInner(ctx)
enddef

