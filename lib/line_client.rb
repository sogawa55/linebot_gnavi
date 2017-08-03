class LineClient
  END_POINT = "https://api.line.me"

  def initialize(channel_access_token, proxy = nil)
    @channel_access_token = channel_access_token
    @proxy = proxy
  end

  def post(path, data)
    #APIを引数にFaradayのインスタンスを生成
    client = Faraday.new(:url => END_POINT) do |conn|
      conn.request :json
      conn.response :json, :content_type => /\bjson$/
      conn.adapter Faraday.default_adapter
      conn.proxy @proxy
    end
　　#Faradayのpostメソッドを実行してLINEサーバにアクセス
    res = client.post do |request|
      request.url path
      request.headers = {
        'Content-type' => 'application/json',
        'Authorization' => "Bearer #{@channel_access_token}"
      }
      request.body = data
    end
    res
  end
　#replyTokenと返答用メッセージをまとめる
  def reply(replyToken, text)

    messages = [
      {
        "type" => "text" ,
        "text" => text
      }
    ]

    body = {
      "replyToken" => replyToken ,
      "messages" => messages
    }
    #HTTPリクエストのパスと返答メッセージを引数にpostメソッド実行
    post('/v2/bot/message/reply', body.to_json)
  end

end