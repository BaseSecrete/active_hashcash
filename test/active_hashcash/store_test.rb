require "test_helper"

class ActiveHashcash::StoreTest < Minitest::Test
  def test_add?
    store = ActiveHashcash::Store.new(Redis.new)
    stamp = ActiveHashcash::Stamp.mint("test")
    assert(store.add?(stamp))
    refute(store.add?(stamp))
  end

  def test_clean
    store = ActiveHashcash::Store.new(Redis.new)
    store.clear
    stamps = [
      ActiveHashcash::Stamp.mint("test", date: Date.today - 3),
      ActiveHashcash::Stamp.mint("test", date: Date.today - 2),
      ActiveHashcash::Stamp.mint("test", date: Date.today - 1),
      ActiveHashcash::Stamp.mint("test", date: Date.today),
      ActiveHashcash::Stamp.mint("test", date: Date.today + 1),
      ActiveHashcash::Stamp.mint("test", date: Date.today + 2),
      ActiveHashcash::Stamp.mint("test", date: Date.today + 3),
    ]
    stamps.each { |stamp| assert(store.add?(stamp)) }
    assert_equal(7, store.redis.keys("active_hashcash_stamps*").size)
    store.clean
    assert_equal(2, store.redis.keys("active_hashcash_stamps*").size)
  end
end
