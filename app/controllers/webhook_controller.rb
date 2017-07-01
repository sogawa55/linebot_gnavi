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

    
    params = JSON.parse(request.body.read ||'{"name":"Not Given"}')
    
    @conn = Faraday::Connection.new(url: 'http://api.gnavi.co.jp/RestSearchAPI/20150630/') do |builder|
      builder.use Faraday::Request::UrlEncoded
      builder.use Faraday::Response::Logger
      builder.use Faraday::Adapter::NetHttp
    end

    event = params["events"][0]
    event_type = event["type"]
    replyToken = event["replyToken"]
    
    output_text = keyword_seach(event['text'])
    messeage = output_text.to_a
    messeage_fix = messeage[3]
    messeage_send = messeage_fix.to_s


    client = LineClient.new(CHANNEL_ACCESS_TOKEN, OUTBOUND_PROXY)
    res = client.reply(replyToken, messeage_send)

    if res.status == 200
      logger.info({success: res})
    else
      logger.info({fail: res})
    end

    render :nothing => true, status: :ok
  end
  
  
   def keyword_seach(search_text)
         # GETでAPIを叩く
    response = @conn.get do |req|
      req.params[:keyid] = 'f7ccc130ee2c327dce69399bc08f71e2'
      req.params[:format] = 'json'
      req.params[:freeword] = search_text
      req.headers['Content-Type'] = 'application/json; charset=UTF-8'
    end
    
    result = JSON.parse(response.body)
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