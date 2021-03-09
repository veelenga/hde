require "./html_date"

class App
  def process(message)
    yield "start", nil

    urls = parse_urls(message)

    elapsed_time = Time.measure do
      urls.each do |url|
        item = process(url)
        yield "process", "#{item[0]} | #{item[1]} | #{item[2]}ms"
      end
    end

    total_execution_time = to_ms(elapsed_time)
    yield "finish", "#{total_execution_time}ms"
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

    {url, date, to_ms(elapsed_time)}
  end

  private def to_ms(time)
    time.total_milliseconds.round.to_i
  end
end
