require "redis"

class Cache
  TTL = 604_800 # 1 week: 7 * 24 * 60 * 60

  def initialize
    @cache_disabled = !!(ENV["CACHE_DISABLED"]?)
    @redis = Redis::PooledClient.new(url: ENV["REDIS_URL"]? || "redis://localhost:6379")
  end

  def save(url, digest, date)
    return if @cache_disabled

    @redis.multi do |multi|
      multi.setex("digest-#{url}", TTL, digest)
      multi.setex("date-#{url}", TTL, date)
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
end
