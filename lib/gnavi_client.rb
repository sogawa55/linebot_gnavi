class GnaviClient
  def initialize(gnavi_key = nil)
    @gnavi_key = gnavi_key
    
  end
  
  

    def keyword_seach(text)
    params = JSON.parse(request.body.read)
    @conn = Faraday::Connection.new(url: 'http://api.gnavi.co.jp/RestSearchAPI/20150630/') do |builder|
      builder.use Faraday::Request::UrlEncoded
      builder.use Faraday::Response::Logger
      builder.use Faraday::Adapter::NetHttp
    end
         # GETでAPIを叩く
    response = @conn.get do |req|
      req.params[:keyid] = ENV['GURUNAVI_API_KEY']
      req.params[:format] = 'json'
      req.params[:freeword] = text
      req.headers['Content-Type'] = 'application/json; charset=UTF-8'
    end
    
    json = JSON.parse(response.body[0])
    result = json['rest']
    return result
    end
end
