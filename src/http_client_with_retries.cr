require "http/client"

class HTTPClientWithRetries
  USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 11_2_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.192 Safari/537.36"

  def fetch(url, max_retries = 3)
    raise ArgumentError.new("too many retries") if max_retries == 0

    response = HTTP::Client.get(url)

    if response.cookies
      uri = URI.parse(url)
      client = HTTP::Client.new uri
      request = HTTP::Request.new("GET", uri.request_target)

      request.headers["user-agent"] = USER_AGENT
      request.headers["cookie"] = cookie_header(response.cookies)

      response = client.exec(request)
    end

    if (300..399).includes?(response.status_code)
      new_url = response.headers["location"]
      return fetch(new_url, max_retries - 1)
    end

    response
  end

  private def cookie_header(cookies)
    cookies.join("; ") { |cookie| "#{cookie.name}=#{cookie.value.gsub(" ", "")}" }
  end
end
