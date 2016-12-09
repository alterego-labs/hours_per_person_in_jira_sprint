class HttpRequester
  attr_reader :url

  def initialize(url)
    @url = url
  end

  def get_json_response
    make_http_request
  end

  def get_paginated_json_response(values_key)
    responses = do_paginated_json_response(0, [])
    responses.compact.reduce({'values' => []}) do |hash, response|
      hash['values'] += response.fetch(values_key, [])
      hash
    end
  end

  def do_paginated_json_response(offset, responses)
    response = make_http_request(offset)
    max_results = response['maxResults'].to_i
    total = response['total'].to_i
    start_at = response['startAt'].to_i
    responses = responses + [response]
    if max_results + start_at >= total
      responses
    else
      do_paginated_json_response(offset + 50, responses)
    end
  end

  def make_http_request(start_at = 0)
    uri = URI.parse(url)
    uri.query = URI.encode_www_form("startAt" => start_at) if start_at != 0
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth(USER_LOGIN, USER_PASSWORD)
    response = http.request(request)
    JSON.parse(response.body)
  end
end
