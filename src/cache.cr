require "redis"

class Cache
  TTL = 604_800 # 1 week: 7 * 24 * 60 * 60

  def initialize
    @cache_disabled = !!(ENV["CACHE_DISABLED"]?)
    @redis = Redis::PooledClient.new(url: ENV["REDIS_URL"]? || "redis://localhost:6379")
  end

  def save(url, digest : String, date : String)
    return if @cache_disabled

    @redis.multi do |multi|
      multi.set("digest-#{url}", digest, ex: TTL)
      multi.set("date-#{url}", date, ex: TTL)
    end
  end

  def get_digest(url)
    return if @cache_disabled

    @redis.get("digest-#{url}")
  end

  def get_date(url)
    return if @cache_disabled

    @redis.get("date-#{url}")
  end

  def close
    return if @cache_disabled

    @redis.close
  end
end
