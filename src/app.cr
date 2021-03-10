require "./html_date"

class App
  alias OutputCallType = String, String? -> Nil

  def process(message, &block : OutputCallType)
    GC.disable

    block.call "start", nil

    urls = parse_urls(message)
    elapsed_time = Time.measure { process_urls(urls, &block) }
    total_execution_time = to_ms(elapsed_time)

    block.call "finish", "#{total_execution_time}ms"
  ensure
    GC.enable
  end

  private def process_urls(urls, &block : OutputCallType)
    channels = urls.map { Channel(Nil).new }

    urls.each_with_index do |url, idx|
      channel = channels[idx]

      spawn do
        item = process_url(url)
        date, time = item[1], item[2]
        block.call "process", "#{url} | #{date} | #{time}ms"
      rescue e
        puts e.inspect_with_backtrace
        block.call "process", "#{url} | NA | NA"
        block.call "error", e.message
      ensure
        channel.send(nil)
      end
    end

    channels.each &.receive
  end

  private def process_url(url)
    date = nil
    elapsed_time = Time.measure do
      date = HtmlDate.extract_from_url(url)
    end

    {url, date || "NA", to_ms(elapsed_time)}
  end

  private def parse_urls(message)
    message
      .gsub('\n', ' ')
      .split(' ', remove_empty: true)
  end

  private def to_ms(time)
    time.total_milliseconds.round.to_i
  end
end
