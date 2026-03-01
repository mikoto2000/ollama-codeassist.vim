vim9script

const AsyncHTTP = vital#ollamacodeassist#import("Web.AsyncHTTP")

var host = "localhost"
var port = 11434
var endpoint_path = "/api/generate"
var endpoint_url = $"http://{host}:{port}{endpoint_path}"

const data_template = {
  "model": "qwen2.5-coder:14b",
#  "model": "qwen2.5:14b-instruct",
#  "model": "codellama:13b",
  "prompt": null,
  "suffix": null,
  "stream": false,
  "options": {
    "stop": ["<|FIM_START|>", "<|FIM_STOP|>", "<|im_start|>", "<|im_end|>"],
  }
}
var data = copy(data_template)
var line = 0
var language = 'unknown'


def UserCb(response: any)
  if response.status == 200
    # コンテキストの行に、レスポンスの内容を挿入する
    var s = json_decode(response.content).response

    # もし \n が文字として入ってくる場合も吸収（保険）
    s = substitute(s, '\\n', "\n", 'g')

    # もし \u0000 が文字として入ってくる場合も吸収（保険）
    s = substitute(s, '\\u0000', "\%x00", 'g')

    # NUL を改行に変換
    s = substitute(s, "\%x00", "\n", 'g')

    # 改行で行分割して挿入
    var lines = split(s, '\r\?\n', 1)
    setline(line, lines[0])
    append(line, lines[1 : -1])
  else
    #echomsg response.status
  endif
enddef

# 現在のバッファからコンテキストを作成する関数
def CreateCurrentBufferContext()
  # 現在の行番号を取得
  line = line('.')

  # 現在のバッファから言語を推測
  if &filetype != ''
    language = &filetype
  endif

  # バッファ全体の内容を取得
  var buffer_prefix = $"// language: {language}\n" .. $"// Please only codes, and not output codeblock text.\n// Don't add closing brackets if they already exist in suffix.\n" .. join(getline(1, '.'), '\n')
  var buffer_suffix = '<|FIM_STOP|>' .. join(getline('.', '$'), '\n')

  ## プレフィックス計算(現在の行より前の10行分を取得)
  #var prefix_start_lnum = max([1, line - 10])
  #var prefix_end_lnum = max([1, line - 1])
  #var buffer_prefix = join(getline(prefix_start_lnum, prefix_end_lnum), "\n")

  ## サフィックス計算（現在の行から10行分を取得）
  #var suffix_start_lnum = min([line('$'), lnum + 1])
  #var suffix_end_lnum = min([line('$'), lnum + 10])
  #var buffer_suffix = join(getline(suffix_start_lnum, suffix_end_lnum), "\n")
  echomsg buffer_suffix

  data.prompt = buffer_prefix
  data.suffix = buffer_suffix
enddef

# コンテキストを基に、コード補完のリクエストを送る関数
def RequestInner()
  AsyncHTTP.request({
        \ 'method': 'POST',
        \ 'url': endpoint_url,
        \ 'data': json_encode(data),
        \ 'userCallback': function('UserCb'),
        \ })
enddef

export def Request()
  CreateCurrentBufferContext()
  RequestInner()
enddef

