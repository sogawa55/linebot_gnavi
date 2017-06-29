class WebhookController < ApplicationController
  # Lineからのcallbackか認証
  protect_from_forgery with: :null_session

  CHANNEL_SECRET = ENV['CHANNEL_SECRET']
  OUTBOUND_PROXY = ENV['OUTBOUND_PROXY']
  CHANNEL_ACCESS_TOKEN = ENV['CHANNEL_ACCESS_TOKEN']

  def callback
    unless is_validate_signature
      render :nothing => true, status: 470
    end
    
  　 # ぐるなびに渡すキーワードの取得
    params = JSON.parse(request.body.read)

    event = params["events"][0]
    event_type = event["type"]
    replyToken = event["replyToken"]
    
    
     conn = Faraday::Connection.new(url: 'http://api.gnavi.co.jp/RestSearchAPI/20150630/') do |builder|
      builder.use Faraday::Request::UrlEncoded
      builder.use Faraday::Response::Logger
      builder.use Faraday::Adapter::NetHttp
    end
    
      send_data = keyword_seach(params, conn)
      send(params, send_data)
      
    def keyword_seach(params, conn)
    search_place = params['result'][0]['content']['text']
    search_place_array = search_place.split("\n")

    if search_place_array.length == 2
      keyword_array = search_place_array[1].split("、")
      gnavi_keyword = keyword_array.join()
    end
    
     # GETでAPIを叩く
    response = conn.get do |req|
      req.params[:keyid] = ENV['GURUNAVI_API_KEY']
      req.params[:format] = 'json'
      req.params[:address] = search_place_array[0]
      req.params[:hit_per_page] = 1
      req.params[:freeword] = gnavi_keyword
      req.params[:freeword_condition] = 2
      req.headers['Content-Type'] = 'application/json; charset=UTF-8'
    end

    json = JSON.parse(response.body)
    result = {}
    result['name'] = json['rest']['name'] if json['rest'].include?('name')
    result['shop_image1'] = json['rest']['image_url']['shop_image1'] if json['rest'].include?('image_url')
    result['address'] = json['rest']['address'] if json['rest'].include?('address')
    result['latitude'] = json['rest']['latitude'] if json['rest'].include?('latitude')
    result['longitude'] = json['rest']['longitude'] if json['rest'].include?('longitude')
    result['opentime'] = json['rest']['opentime'] if json['rest'].include?('opentime')
    return result
    end
    
    output_text = result

    client = LineClient.new(CHANNEL_ACCESS_TOKEN, OUTBOUND_PROXY)
    res = client.reply(replyToken, output_text)

    if res.status == 200
      logger.info({success: res})
    else
      logger.info({fail: res})
    end

    render :nothing => true, status: :ok
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