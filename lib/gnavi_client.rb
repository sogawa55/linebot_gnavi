class GnaviClient
  def initialize(gnavi_key = nil)
    @gnavi_key = gnavi_key
  end
  
    def keyword_seach(params,conn)
         # GETでAPIを叩く
    response = conn.get do |req|
      req.params[:keyid] = ENV['GURUNAVI_API_KEY']
      req.params[:format] = 'json'
      req.params[:freeword] = params['text']
      req.headers['Content-Type'] = 'application/json; charset=UTF-8'
    end
    
    result = JSON(response.body)
    
    return result
  end
end
