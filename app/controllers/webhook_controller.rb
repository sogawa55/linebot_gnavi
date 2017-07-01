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
    
    event = params["events"][0]
    event_type = event["type"]
    replyToken = event["replyToken"]
    input_text = event["message"]["text"]
    
    conn = Faraday::Connection.new(url: 'http://api.gnavi.co.jp/RestSearchAPI/20150630/') do |builder|
      builder.use Faraday::Request::UrlEncoded
      builder.use Faraday::Response::Logger
      builder.use Faraday::Adapter::NetHttp
    end
    
             # GETでAPIを叩く
    output_text = keyword_search(conn, input_text)
    message = [] 
    message.push(output_text["rest"][1]["name"])
    send_message = message[0]


    client = LineClient.new(CHANNEL_ACCESS_TOKEN, OUTBOUND_PROXY)
    res = client.reply(replyToken, send_message)

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
      req.params[:freeword]= input_text
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