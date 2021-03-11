require "xml"
require "./sanitize/blacklist"

class HtmlDate
  LD_JSON_PATTERN_PUBLISHED = /datePublished": ?"([0-9]{4}-[0-9]{2}-[0-9]{2})/
  LD_JSON_PATTERN_MODIFIED  = /dateModified": ?"([0-9]{4}-[0-9]{2}-[0-9]{2})/
  META_CONTENT_ATTRIBUTES   = %w(
    article:modified_time
    last-modified
    OG:Updated_Time
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
    dc:created
    created
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
  ABBR_CLASS_ATTRIBUTES = [
    "published",
    "date-published",
    "time published",
  ]

  PARSE_DATE_PATTERNS = [
    "%F",         # ISO 8601 date (2016-04-05)
    "%D",         # date (04/05/16)
    "%c",         # date and time (Tue Apr 5 10:26:19 2016)
    "%d.%m.%y",   # 03.01.2021
    "%-d.%-m.%y", # 3.1.2021
  ]
  TIMESTAMP_SEARCH_PATTERN       = /([0-9]{4}-[0-9]{2}-[0-9]{2}|[0-9]{2}\.[0-9]{2}\.[0-9]{4}).[0-9]{2}:[0-9]{2}:[0-9]{2}/
  TIMESTAMP_SEARCH_REJECTED_TAGS = %w(
    audio
    abbr
    canvas
    embed
    figcaption
    footer
    form
    frame
    iframe
    link
    meta
    math
    svg
    picture
    noscript
    object
    picture
    script
    video
  )

  def initialize
    @min_date = Time.unix(0)
    @max_date = Time.utc
  end

  def extract_from_html(html)
    node = XML.parse_html(html)

    date = search_meta_nodes(node)
    date ||= search_ldjson(node)
    date ||= search_abbr_nodes(node)
    date ||= search_time_nodes(node)
    date ||= search_timestamps(html)

    date.try &.to_s("%b %-d, %Y")
  end

  private def search_meta_nodes(node) : Time?
    meta_content_node = node.xpath_nodes("//meta").find do |meta_node|
      content_attribute_matches = meta_node.attributes.any? do |attr|
        attr.content.in?(META_CONTENT_ATTRIBUTES)
      end

      meta_node if content_attribute_matches
    end

    try_parse_date(meta_content_node.try &.["content"])
  end

  private def search_ldjson(node) : Time?
    json_node = node.xpath_node(%q(.//script[@type="application/ld+json"]|//script[@type="application/settings+json"]))
    return if json_node.nil? || !json_node.content.includes?("date")

    result = LD_JSON_PATTERN_MODIFIED.match(json_node.content) ||
             LD_JSON_PATTERN_PUBLISHED.match(json_node.content)

    try_parse_date(result.try &.[1])
  end

  private def search_abbr_nodes(node) : Time?
    nodes = node.xpath_nodes("//abbr")

    # search for abbr tags using class attributes
    filtered_by_class = nodes.select do |abbr|
      abbr.attributes.any? do |attr|
        attr.name == "class" && attr.content.in?(ABBR_CLASS_ATTRIBUTES)
      end
    end

    date = filtered_by_class.compact_map do |abbr_attr|
      title = abbr_attr.attributes.find { |attr| attr.name == "title" }.try &.content
      candidate_date = try_parse_date(title) if title
      candidate_date ||= try_parse_date(abbr_attr.text.gsub("am ", "")) if abbr_attr.text
      candidate_date
    end.sort!.last?

    return date if date

    # search for abbr tags using data-utime
    nodes.each_with_object([] of Time) do |abbr, obj|
      abbr.attributes.each do |attr|
        if attr.name == "data-utime" && (value = attr.content.to_i?)
          date = try_parse_unix(value)
          obj << date if date
        end
      end
    end.sort!.last?
  end

  private def search_time_nodes(node) : Time?
    nodes = node.xpath_nodes(".//time")

    nodes.each_with_object([] of Time) do |abbr, obj|
      can_use_datetime = abbr.attributes.find { |attr| attr.name == "pubdate" }
      can_use_datetime ||= abbr.attributes.find do |attr|
        attr.name == "class" &&
          (attr.content == "entry-date" || attr.content == "entry-time")
      end

      if can_use_datetime && (datetime = abbr.attributes.find { |attr| attr.name == "datetime" })
        date = try_parse_date(datetime.content)
        obj << date if date
      else
        date = try_parse_date(abbr.text)
        obj << date if date
      end
    end.sort!.last?
  end

  private def search_timestamps(htmlstring)
    html = Sanitize::Blacklist
      .new(rejectable_tags: TIMESTAMP_SEARCH_REJECTED_TAGS)
      .process(htmlstring)

    result = TIMESTAMP_SEARCH_PATTERN.match html
    try_parse_date(result.try &.[1])
  end

  private def try_parse_date(candidate : String?, patterns = PARSE_DATE_PATTERNS) : Time?
    return if candidate.nil? || candidate.size < 7

    patterns.each do |pattern|
      date = Time.parse_utc(candidate, pattern) rescue nil
      return date if date && date >= @min_date && date <= @max_date
    end
  end

  private def try_parse_unix(date : Int?) : Time?
    return if date.nil?

    date = Time.unix(date) rescue nil
    return date if date && date >= @min_date && date <= @max_date
  end
end
