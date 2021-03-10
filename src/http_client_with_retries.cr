require "http/client"

class HTTPClientWithRetries
  def fetch(url, max_retries = 2)
    raise ArgumentError.new("too many retries") if max_retries == 0

    response = HTTP::Client.get(url)

    if response.cookies
      uri = URI.parse(url)
      client = HTTP::Client.new uri
      request = HTTP::Request.new("GET", uri.request_target)

      cookie_header = response.cookies.map { |cookie| "#{cookie.name}=#{cookie.value.gsub(" ", "")}" }.join("; ")

      request.headers["user-agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 11_2_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.192 Safari/537.36"
      request.headers["cookie"] = cookie_header
      response = client.exec(request)
    end

    if response.status_code == 301
      new_url = response.headers["location"]
      return fetch(new_url, max_retries - 1)
    end

    response
  end
end
