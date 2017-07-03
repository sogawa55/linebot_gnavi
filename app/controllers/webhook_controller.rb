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
    input_text = event["message"]["text"]
    
    if event["message"]["type"] = "text"
         default_message = "位置情報を入力してください。"
         $send_message = default_message
         
    elsif event["message"]["type"] = "location"
         latitude = event.message['latitude'] # 緯度
         longitude = event.message['longitude'] # 経度
         $data = keyword_search(conn, latitude,longitude)
         
         rest_name = [] 
         rest_name.push($data["rest"][0]["name"],
                   $data["rest"][1]["name"],
                   $data["rest"][2]["name"],
                   $data["rest"][3]["name"],
                   $data["rest"][4]["name"])
          
        
         rest_url = []
         rest_url.push($data["rest"][0]["url"],
                  $data["rest"][1]["url"],
                  $data["rest"][2]["url"],
                  $data["rest"][3]["url"],
                  $data["rest"][4]["url"])
         
    else
         default_message = "位置情報を入力してください。"
    end 
  
    result_message = rest_name[0] + "\n" + rest_url[0] + "\n" + "\n" +
                     rest_name[1] + "\n" + rest_url[1] + "\n" + "\n" +
                     rest_name[2] + "\n" + rest_url[2] + "\n" + "\n" +
                     rest_name[3] + "\n" + rest_url[3] + "\n" + "\n" +
                     rest_name[4] + "\n" + rest_url[4] 
    
    
    if result_message.nil?
      $send_message = default_message
    else
      $send_message = result_message
    end
                   
    client = LineClient.new(CHANNEL_ACCESS_TOKEN, OUTBOUND_PROXY)
    res = client.reply(replyToken, $send_message)


    if res.status == 200
      logger.info({success: res})
    else
      logger.info({fail: res})
    end

    render :nothing => true, status: :ok
  end
  
  def keyword_search(conn, input_text)
    
      response = conn.get do |req|
      req.params[:keyid] = 'f7ccc130ee2c327dce69399bc08f71e2'
      req.params[:format] = 'json'
      req.params[:latitude] = latitude
      req.params[:longitude] = longitude
      req.params[:hit_per_page] = 5
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