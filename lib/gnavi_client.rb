class GnaviClient
  def initialize(gnavi_key = nil)
    @gnavi_key = gnavi_key
    
      @conn = Faraday::Connection.new(url: 'http://api.gnavi.co.jp/RestSearchAPI/20150630/') do |builder|
      builder.use Faraday::Request::UrlEncoded
      builder.use Faraday::Response::Logger
      builder.use Faraday::Adapter::NetHttp
    end
    
    
  end
  

    def keyword_seach(text)
         # GETでAPIを叩く
    response = @conn.get do |req|
      req.params[:keyid] = ENV['GURUNAVI_API_KEY']
      req.params[:format] = 'json'
      req.params[:freeword] = text
      req.headers['Content-Type'] = 'application/json; charset=UTF-8'
    end
    
    json = JSON.parse(response.body)
    result = {}
    result['name'] = json['rest']['name'] if json['rest'].include?('name')
    return result['name'][0]
    end
end
