module ActiveHashcash
  class Store
    attr_reader :redis

    def initialize(redis = Redis.new(url: ActiveHashcash.redis_url || ENV["ACTIVE_HASHCASH_REDIS_URL"] || ENV["REDIS_URL"]))
      @redis = redis
    end

    def add?(stamp)
      redis.sadd(key_on(stamp.date), stamp.to_s) == 0 ? nil : self
    end

    def clear
      redis.del(redis.keys(KEY_PREFIX + "*"))
    end

    KEY_PREFIX = "ActiveHashcash::stamps_on_"

    def key_on(date)
      KEY_PREFIX + date
    end

    def clean
      today = Date.today.strftime("%y%m%d")
      yesterday = (Date.today - 1).strftime("%y%m%d")
      keep = [key_on(today), key_on(yesterday)]
      keys = redis.keys("#{KEY_PREFIX}*")
      redis.del(keys - keep)
    end
  end
end
