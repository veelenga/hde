require "xml"

module HtmlDate
  extend self

  META_CONTENT_ATTRIBUTES = %w(
    pubdate
    publishdate
    timestamp
    dc.date.issued
    dc:date
    article:published_time
    og:article:published_time
    og:published_time
    rnews:datepublished
    date
    bt:pubdate
    sailthru.date
    article.published
    published-date
    date_published
    datepublished
    cxenseparse:recs:publishtime
    article.created
    article_date_original
  )

  class Client
    def fetch(url, max_retries = 2)
      raise ArgumentError.new("retries are too deep") if max_retries == 0

      response = HTTP::Client.get(url)

      if response.status_code == 301
        new_url = response.headers["location"]
        return fetch(new_url, max_retries - 1)
      end

      response
    end
  end

  def extract_from_url(url)
    response = Client.new.fetch(url)

    return if !response.success? || response.body.empty?

    extract_from_html(response.body)
  end

  def extract_from_html(html)
    node = XML.parse_html(html)
    date = search_header(node)
    formatDate(date) if date
  end

  private def search_header(node)
    return unless header = node.xpath_node("//header")

    meta_content_node = header.xpath_nodes("//meta").find do |meta_node|
      content_attribute_matches = meta_node.attributes.any? do |attr|
        attr.content.in?(META_CONTENT_ATTRIBUTES)
      end

      meta_node if content_attribute_matches
    end

    meta_content_node["content"] if meta_content_node
  end

  private def formatDate(date)
    Time.parse_utc(date, "%F").to_s("%b %-d, %Y")
  end
end
