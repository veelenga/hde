class App
  def process(message)
    yield "start", nil

    extract_urls(message).each do |url|
      yield "process", url
    end

    yield "finish", ""
  rescue e
    yield "error", e.message
  end

  private def extract_urls(message)
    message
      .gsub('\n', ' ')
      .split(' ', remove_empty: true)
  end
end
