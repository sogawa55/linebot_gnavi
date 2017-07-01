class GnaviClient
  def initialize(gnavi_key = nil)
    @gnavi_key = gnavi_key
    
  end
  

    def keyword_seach(search_text)
    @conn = Faraday::Connection.new(url: 'http://api.gnavi.co.jp/RestSearchAPI/20150630/') do |builder|
      builder.use Faraday::Request::UrlEncoded
      builder.use Faraday::Response::Logger
      builder.use Faraday::Adapter::NetHttp
    end
         # GETでAPIを叩く
    
    
         
    response = @conn.get do |req|
      req.params[:keyid] = 'f7ccc130ee2c327dce69399bc08f71e2'
      req.params[:format] = 'json'
      req.params[:freeword] = search_text
      req.headers['Content-Type'] = 'application/json; charset=UTF-8'
    end
    
    result = response.body
    return result['rest']['name']
    end
end
