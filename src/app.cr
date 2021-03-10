require "./html_date"
require "./http_client_with_retries"
require "redis"
require "log"

class App
  LAST_MODIFIED_TIME_FORMAT = "%a, %-d %b %Y %H:%M:%S %^Z"
  Log                       = ::Log.for("app")

  alias OutputCallType = String, String? -> Nil

  def initialize
    @redis = Redis::PooledClient.new
  end

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
        cache_date(url, date)
      rescue e
        Log.error { e.inspect_with_backtrace }
        block.call "process", "#{url} | NA | NA"
        block.call "error", e.message
      ensure
        channel.send(nil)
      end
    end

    channels.each &.receive
  end

  private def process_url(url)
    Log.debug { "Start processing URL: #{url}" }

    date = nil
    elapsed_time = Time.measure { date = extract_date(url) }
    ms = to_ms(elapsed_time)

    Log.debug { "URL processed: #{url} | #{date} | #{ms}" }

    {url, date || "NA", ms}
  end

  private def extract_date(url)
    response = HTTPClientWithRetries.new.fetch(url)
    return if !response.success? || response.body.empty?
    cached_date(url, response) || HtmlDate.extract_from_html(response.body)
  end

  private def cached_date(url, response)
    return if ENV["CACHE_DISABLED"]?
    return unless last_modified_date = response.headers["last-modified"]?
    return unless modified_at = (Time.parse!(last_modified_date, LAST_MODIFIED_TIME_FORMAT) rescue nil)

    if modified_at.to_utc < Time.utc
      date = @redis.get(url)
      Log.debug { "Date found in cache: #{date} #{url}" } if date
      return date
    end
  end

  private def cache_date(url, date)
    @redis.set(url, date)
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
