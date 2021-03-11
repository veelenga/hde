require "digest/md5"
require "./cache"
require "./html_date"
require "./http_client_with_retries"

class App
  LAST_MODIFIED_TIME_FORMAT = "%a, %-d %b %Y %H:%M:%S %^Z"
  Log                       = ::Log.for("app")

  alias OutputCallType = String, String? -> Nil

  def initialize
    @cache = Cache.new
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
        date, time = item[0], item[1]
        block.call "process", "#{url} | #{date} | #{time}ms"
      rescue e
        Log.error { e.inspect_with_backtrace }
        block.call "process", "#{url} | NA | NA"
        block.call "error", "#{url} | #{e.message}"
      ensure
        channel.send(nil)
      end
    end

    channels.each &.receive
  end

  private def process_url(url)
    Log.debug { "Start processing URL: #{url}" }

    date = nil
    ms = to_ms(Time.measure { date = extract_date(url) })

    Log.debug { "URL processed: #{url} | #{date} | #{ms}" }

    {date || "NA", ms}
  end

  private def extract_date(url)
    response = HTTPClientWithRetries.new.fetch(url)
    return if !response.success? || response.body.empty?

    digest = Digest::MD5.base64digest(response.body)
    date = lookup_cache(url, response, digest) || HtmlDate.new.extract_from_html(response.body)
    @cache.save(url, digest, date) if date
    date
  end

  private def lookup_cache(url, response, content_digest)
    return unless date = @cache.get_date(url)

    if not_modified?(response) || @cache.get_digest(url) == content_digest
      Log.debug { "Date found in cache: #{url} | #{date}" }
      return date
    end
  end

  private def not_modified?(response)
    return unless last_modified_date = response.headers["last-modified"]?
    return unless modified_at = (Time.parse!(last_modified_date, LAST_MODIFIED_TIME_FORMAT) rescue nil)

    modified_at.to_utc < Time.utc
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
