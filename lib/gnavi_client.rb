class GnaviClient
  def initialize(gnavi_key = nil)
    @gnavi_key = gnavi_key
  end
  
    def keyword_seach(params,conn)
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
    
    result = response.body
    
    return result
  end
end
