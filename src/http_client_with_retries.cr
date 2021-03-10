require "http/client"

class HTTPClientWithRetries
  def fetch(url, max_retries = 2)
    raise ArgumentError.new("too many retries") if max_retries == 0

    response = HTTP::Client.get(url)

    if response.status_code == 301
      new_url = response.headers["location"]
      return fetch(new_url, max_retries - 1)
    end

    response
  end
end
