class App
  def process(message)
    urls = extract_urls(message)

    urls.each do |url|
      yield "process", url
    end
  end

  private def extract_urls(message)
    message
      .gsub('\n', ' ')
      .split(' ', remove_empty: true)
  end
end
