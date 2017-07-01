class GnaviClient
  def initialize(gnavi_key = nil)
    @gnavi_key = gnavi_key
    
  end
  

    def keyword_seach(search_text,conn)
         # GETでAPIを叩く
    response = @conn.get do |req|
      req.params[:keyid] = 'f7ccc130ee2c327dce69399bc08f71e2'
      req.params[:format] = 'json'
      req.params[:freeword] = search_text
      req.headers['Content-Type'] = 'application/json; charset=UTF-8'
    end
    
    result = JSON.parse(response.body)
    result = {}
    result['name'] = json['rest']['name'] if json['rest'].include?('name')
    return result
    end
    
end
