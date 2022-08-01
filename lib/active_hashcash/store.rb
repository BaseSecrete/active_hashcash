module ActiveHashcash
  class Store
    attr_reader :redis

    def initialize(redis)
      @redis = redis
    end

    def add?(stamp)
      redis.sadd("active_hashcash_stamps_#{stamp.date}", stamp) ? self : nil
    end

    def clear
      redis.del(redis.keys("active_hashcash_stamps*"))
    end
  end
end
