class WebhookController < ApplicationController
  # Lineからのcallbackか認証
  protect_from_forgery with: :null_session

  CHANNEL_SECRET = ENV['CHANNEL_SECRET']
  OUTBOUND_PROXY = ENV['OUTBOUND_PROXY']
  CHANNEL_ACCESS_TOKEN = ENV['CHANNEL_ACCESS_TOKEN']
  GURUNAVI_API_KEY = ENV['GURUNAVI_API_KEY']
  
 
  def callback
    unless is_validate_signature
      render :nothing => true, status: 470
    end
    
    conn = Faraday::Connection.new(url: 'http://api.gnavi.co.jp/RestSearchAPI/20150630/') do |builder|
      builder.use Faraday::Request::UrlEncoded
      builder.use Faraday::Response::Logger
      builder.use Faraday::Adapter::NetHttp
    end
    
    event = params["events"][0]
    event_type = event["type"]
    replyToken = event["replyToken"]
    
    if event["message"]["type"] == "text" then
         default_message = "位置情報を入力してください。"
         send_message = default_message
         
    elsif event["message"]["type"] == "location" then
          latitude = event["message"]["latitude"] # 緯度
          longitude = event["message"]["longitude"] # 経度
          data = keyword_search(conn, latitude,longitude)
          count = data["total_hit_count"]
         　if count > 1
         　   count.times do |x| 
         　   y = x-1  
         　   rest_name =  []
         　   rest_name.push(data["rest"][y]["name"]) 
         　   end   
         　  
         　   z = 0
         　   rest_name.each do |name|
         　   result_message[z] = name + "\n"
         　   z += 1
         　   
         　   send_message = result_message
         　   end
         　   
        　else
         　  notfount_messeage = "検索結果はありません"
          　send_message = notfount_messeage 
         
    else
        send_message = "失敗や"
    end 

    
                   
    client = LineClient.new(CHANNEL_ACCESS_TOKEN, OUTBOUND_PROXY)
    res = client.reply(replyToken, send_message)


    if res.status == 200
      logger.info({success: res})
    else
      logger.info({fail: res})
    end

    render :nothing => true, status: :ok
  end
  
  def keyword_search(conn, latitude,longitude)
    
      response = conn.get do |req|
      req.params[:keyid] = 'f7ccc130ee2c327dce69399bc08f71e2'
      req.params[:format] = 'json'
      req.params[:latitude] = latitude
      req.params[:longitude] = longitude
      req.params[:hit_per_page] = 5
      req.params[:bottomless_cup] = 1
      req.headers['Content-Type'] = 'application/json; charset=UTF-8'
    end
    
    json = JSON.parse(response.body)
    result  = json
    return result
  end 
  
  
  
  private
  # verify access from LINE
  def is_validate_signature
    signature = request.headers["X-LINE-Signature"]
    http_request_body = request.raw_post
    hash = OpenSSL::HMAC::digest(OpenSSL::Digest::SHA256.new, CHANNEL_SECRET, http_request_body)
    signature_answer = Base64.strict_encode64(hash)
    signature == signature_answer
  end
end
