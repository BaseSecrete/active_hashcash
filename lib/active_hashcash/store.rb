module ActiveHashcash
  class Store
    attr_reader :redis

    def initialize(redis = Redis.new(url: ActiveHashcash.redis_url || ENV["ACTIVE_HASHCASH_REDIS_URL"] || ENV["REDIS_URL"]))
      @redis = redis
    end

    def add?(stamp)
      redis.sadd("active_hashcash_stamps_#{stamp.date}", stamp) ? self : nil
    end

    def clear
      redis.del(redis.keys("active_hashcash_stamps*"))
    end

    def clean
      today = Date.today.strftime("%y%m%d")
      yesterday = (Date.today - 1).strftime("%y%m%d")
      keep = ["active_hashcash_stamps_#{today}", "active_hashcash_stamps_#{yesterday}"]
      keys = redis.keys("active_hashcash_stamps*")
      redis.del(keys - keep)
    end
  end
end
