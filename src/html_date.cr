require "xml"

module HtmlDate
  extend self

  LD_JSON_PATTERN_PUBLISHED = /datePublished": ?"([0-9]{4}-[0-9]{2}-[0-9]{2})/
  LD_JSON_PATTERN_MODIFIED  = /dateModified": ?"([0-9]{4}-[0-9]{2}-[0-9]{2})/
  META_CONTENT_ATTRIBUTES   = %w(
    article:modified_time
    modified_time
    og:article:modified_time
    og:updated_time
    release_date
    updated_time
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
    datePublished
    uploadDate
  )

  def extract_from_html(html)
    node = XML.parse_html(html)

    date = search_meta(node.xpath_node("//head"))
    date ||= search_ldjson(node)
    date ||= search_meta(node.xpath_node("//body"))
    formatDate(date) if date
  end

  private def search_meta(node)
    meta_content_node = node.not_nil!.xpath_nodes("//meta").find do |meta_node|
      content_attribute_matches = meta_node.attributes.any? do |attr|
        attr.content.in?(META_CONTENT_ATTRIBUTES)
      end

      meta_node if content_attribute_matches
    end

    meta_content_node["content"] if meta_content_node
  end

  private def search_ldjson(node)
    json_node = node.xpath_node(%q(.//script[@type="application/ld+json"]|//script[@type="application/settings+json"]))
    return if json_node.nil? || !json_node.content.includes?("date")

    result = LD_JSON_PATTERN_MODIFIED.match(json_node.content) ||
             LD_JSON_PATTERN_PUBLISHED.match(json_node.content)

    result.try &.[1]
  end

  private def formatDate(date)
    Time.parse_utc(date, "%F").to_s("%b %-d, %Y")
  end
end
