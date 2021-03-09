require "./html_date"

class App
  def process(message)
    yield "start", nil

    parse_urls(message).each do |url|
      item = process(url)
      yield "process", "#{item[0]} | #{item[1]} | #{item[2]}ms"
    end

    yield "finish", ""
  rescue e
    puts e.inspect_with_backtrace
    yield "error", e.message
  end

  private def parse_urls(message)
    message
      .gsub('\n', ' ')
      .split(' ', remove_empty: true)
  end

  private def process(url)
    date = nil
    elapsed_time = Time.measure do
      date = HtmlDate.extract_from_url(url) || "NA"
    end
    ms = elapsed_time.total_milliseconds.round.to_i

    {url, date, ms}
  end
end
