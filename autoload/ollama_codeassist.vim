vim9script

const AsyncHTTP = vital#ollamacodeassist#import("Web.AsyncHTTP")

var host = "localhost"
var port = 11434
var endpoint_path = "/api/generate"
var endpoint_url = $"http://{host}:{port}{endpoint_path}"

const data_template = {
  "model": "qwen2.5:14b-instruct",
  "prompt": null,
  "stream": false,
}

const prompt_template =<< trim END
次の ${language} プログラムの ${line} 行目に不足しているコードを教えてください。
もっとも可能性の高いコードを、コードのみ出力してください。コードブロックも不要です。


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

var dummy_buffer =<< END
// 標準出力に「ハローハローボー」と出力する
public class HelloWorld {
    public static void main(String[] args) {

    }
}
END

def UserCb(response: any)
  if response.status == 200
    echomsg json_decode(response.content).response
  else
    echomsg response.status
  endif
enddef

var context = Context.new('java', 3, join(dummy_buffer, '\n'))

def RequestInner(ctx: Context)
  echomsg join(prompt_template, "\n")

  var prompt = substitute(join(prompt_template, "\n"), '${language}', ctx.language, 'g')
  prompt = substitute(prompt, '${line}', ctx.line, 'g')
  prompt = substitute(prompt, '${buffer}', ctx.buffer, 'g')

  var data = copy(data_template)
  data.prompt = prompt

  echomsg endpoint_url
  echomsg json_encode(data)

  AsyncHTTP.request({
        \ 'method': 'POST',
        \ 'url': endpoint_url,
        \ 'data': json_encode(data),
        \ 'userCallback': function('UserCb'),
        \ })
enddef

RequestInner(context)
