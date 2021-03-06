class WebhookController < ApplicationController
  # Lineからのcallbackか認証
  protect_from_forgery with: :null_session
  CHANNEL_SECRET = ENV['CHANNEL_SECRET']
  OUTBOUND_PROXY = ENV['OUTBOUND_PROXY']
  CHANNEL_ACCESS_TOKEN = ENV['CHANNEL_ACCESS_TOKEN']
  GURUNAVI_API_KEY = ENV['GURUNAVI_API_KEY']
  
  #LINEにメッセージが送信されたらcallback関数を実行
  def callback
    unless is_validate_signature
      render :nothing => true, status: 470
    end
    
    #Faradayを用いてぐるなびAPIのインスタンスを生成
    conn = Faraday::Connection.new(url: 'http://api.gnavi.co.jp/RestSearchAPI/20150630/') do |builder|
      builder.use Faraday::Request::UrlEncoded
      builder.use Faraday::Response::Logger
      builder.use Faraday::Adapter::NetHttp
    end
    
    #リクエストメッセージから内容を格納
    event = params["events"][0]
    event_type = event["type"]
    replyToken = event["replyToken"]
    
    #リクエストメッセージが位置情報かをチェック
    if event["message"]["type"] == "text" then
         default_message = "位置情報を入力してください。"
         send_message = default_message
         
    elsif event["message"]["type"] == "location" then
          latitude = event["message"]["latitude"] # 緯度
          longitude = event["message"]["longitude"] # 経度
          #位置情報を引数にぐるなび検索実行してデータを取得
          data = keyword_search(conn, latitude,longitude)
          rest_name = []
          count = data["total_hit_count"].to_i
          
          
          #検索データが1件以上かをチェック
          x = 0
          if 	count >= 1
          data["rest"].each do |rest|
            #取得したデータから店名とURLを配列として格納
            rest_name[x] = rest["name"] + "\n" + rest["url"] + "\n"
            x += 1 
          end
          #joinメソッドで改行を挿入しつつ文字列に変換して格納
          result_name = "#{count}件見つけたよ。" + "\n\n" + rest_name.join("\n")
      
          send_message = result_name
          
          else
            send_message = "見つからなかったよ。もう少し移動してみて。"
          end
    
      else
         send_message = "失敗"
    end 
    
    #LINEクライアントのインスタンス生成              
    client = LineClient.new(CHANNEL_ACCESS_TOKEN, OUTBOUND_PROXY)
    res = client.reply(replyToken, send_message)


    if res.status == 200
      logger.info({success: res})
    else
      logger.info({fail: res})
    end
    #何も表示しない
    render :nothing => true, status: :ok
  end
  
  #位置情報検索の実行
  def keyword_search(conn, latitude,longitude)
    
      response = conn.get do |req|
      req.params[:keyid] = 'f7ccc130ee2c327dce69399bc08f71e2'
      req.params[:format] = 'json'
      req.params[:latitude] = latitude
      req.params[:longitude] = longitude
      req.params[:hit_per_page] = 10
      req.params[:wifi] = 1
      req.params[:outret] = 1 
      req.params[:lunch] = 1
      req.headers['Content-Type'] = 'application/json; charset=UTF-8'
    end
    
    #jsonデータを読み込み
    json = JSON.parse(response.body)
    result  = json
    return result
  end 
  
  
  
  private
  #verify access from LINE
  def is_validate_signature
    signature = request.headers["X-LINE-Signature"]
    http_request_body = request.raw_post
    hash = OpenSSL::HMAC::digest(OpenSSL::Digest::SHA256.new, CHANNEL_SECRET, http_request_body)
    signature_answer = Base64.strict_encode64(hash)
    signature == signature_answer
  end
end
