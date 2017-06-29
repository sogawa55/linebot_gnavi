class GnaviClient
  def initialize(gnavi_key = nil)
    @gnavi_key = gnavi_key
    
      @conn = Faraday::Connection.new(url: 'http://api.gnavi.co.jp/RestSearchAPI/20150630/') do |builder|
      builder.use Faraday::Request::UrlEncoded
      builder.use Faraday::Response::Logger
      builder.use Faraday::Adapter::NetHttp
    end
    
    
  end
  

    def keyword_seach(params)
         # GETでAPIを叩く
    response = @conn.get do |req|
      req.params[:keyid] = ENV['GURUNAVI_API_KEY']
      req.params[:format] = 'json'
      req.params[:freeword] = params['text']
      req.headers['Content-Type'] = 'application/json; charset=UTF-8'
    end
    
    result = JSON(response.body)
    
    return result
  end
end
