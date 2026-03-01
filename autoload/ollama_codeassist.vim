vim9script

const AsyncHTTP = vital#ollamacodeassist#import("Web.AsyncHTTP")

var host = "localhost"
var port = 11434
var endpoint_path = "/api/generate"
var endpoint_url = $"http://{host}:{port}{endpoint_path}"

const data_template = {
  "model": "qwen2.5:14b-instruct",
#  "model": "codellama:13b",
  "prompt": null,
  "stream": false,
}

const prompt_template =<< trim END
次の ${language} プログラムの ${line} 行目のコードが不足しています。
${line} 行目のコードを、前後のコードを参考にして補完してください。
補完するのは ${line} 行目のコードのみとしてください。
もっとも可能性の高いコードを、コードのみ出力してください。
説明文は出力しないでください。
コードブロックも出力しないでください。


```${language}
${buffer}
```
END

class Context
  var language: string
  var line: number
  var buffer: string

  def new(language: string, line: number, buffer: string)
    this.language = language
    this.line = line
    this.buffer = buffer
  enddef
endclass

var context: Context

def UserCb(response: any)
  if response.status == 200
    # コンテキストの行に、レスポンスの内容を挿入する
    var s = json_decode(response.content).response

    # もし \u0000 が文字として入ってくる場合も吸収（保険）
    s = substitute(s, '\\u0000', "\%x00", 'g')

    # NUL を改行に変換
    s = substitute(s, "\%x00", "\n", 'g')

    # 改行で行分割して挿入
    var lines = split(s, '\r\?\n', 1)
    setline(context.line, lines[0])
    append(context.line, lines[1 : -1])
  else
    #echomsg response.status
  endif
enddef

# 現在のバッファからコンテキストを作成する関数
def CreateCurrentBufferContext(): Context
  var language = 'unknown'
  var line = 0
  var buffer = ''

  # 現在のバッファから言語を推測
  if &filetype != ''
    language = &filetype
  endif

  # 現在の行番号を取得
  line = line('.')

  # バッファ全体の内容を取得
  buffer = join(getline(1, '$'), '\n')

  return Context.new(language, line, buffer)
enddef

# コンテキストを基に、コード補完のリクエストを送る関数
def RequestInner(ctx: Context)
  #echomsg join(prompt_template, "\n")

  var prompt = substitute(join(prompt_template, "\n"), '${language}', ctx.language, 'g')
  prompt = substitute(prompt, '${line}', ctx.line, 'g')
  prompt = substitute(prompt, '${buffer}', ctx.buffer, 'g')

  var data = copy(data_template)
  data.prompt = prompt

  #echomsg endpoint_url
  #echomsg json_encode(data)

  AsyncHTTP.request({
        \ 'method': 'POST',
        \ 'url': endpoint_url,
        \ 'data': json_encode(data),
        \ 'userCallback': function('UserCb'),
        \ })
enddef

export def Request()
  context = CreateCurrentBufferContext()
  RequestInner(context)
enddef

