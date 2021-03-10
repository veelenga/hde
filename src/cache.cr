require "redis"

class Cache
  DEFAULT_TTL = 7 * 24 * 60 * 60

  def initialize
    @cache_disabled = !!(ENV["CACHE_DISABLED"]?)
    @redis = Redis::PooledClient.new
  end

  def save(url, digest, date)
    return if @cache_disabled

    @redis.multi do |multi|
      multi.setex("digest-#{url}", DEFAULT_TTL, digest)
      multi.setex("date-#{url}", DEFAULT_TTL, date)
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
