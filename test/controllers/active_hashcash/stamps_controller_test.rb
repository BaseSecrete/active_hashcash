require "test_helper"

module ActiveHashcash
  class StampsControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    ActiveHashcash.bits = 2 # Decrease complexity for speed

    def test_session_without_hashcash
      post(session_path)
      assert_response(:unprocessable_entity)
    end

    def test_session_with_malformed_hashcash
      post(session_path, params: {hashcash: "malformed"})
      assert_response(:unprocessable_entity)
    end

    def test_session_with_wrong_hashcash
      hashcash = ActiveHashcash::Stamp.mint("wrong resource")
      post(session_path, params: {hashcash: hashcash})
      assert_response(:unprocessable_entity)
    end

    def test_session_with_authentic_hashcash_spent_twice
      hashcash = ActiveHashcash::Stamp.mint("www.example.com")
      assert_difference("ActiveHashcash::Stamp.count") do
        post(session_path, params: {hashcash: hashcash})
        assert_response(200)
      end

      stamp = ActiveHashcash::Stamp.last
      assert_equal("127.0.0.1", stamp.ip_address)
      assert_equal("/session", stamp.request_path)
      assert_equal({"more" => "details"}, stamp.context)

      assert_no_difference("ActiveHashcash::Stamp.count") do
        post(session_path, params: {hashcash: hashcash})
        assert_response(:unprocessable_entity, "Stamp cannot be spent twice")
      end
    end
  end
end
