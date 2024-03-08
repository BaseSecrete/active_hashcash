require "test_helper"

module ActiveHashcash
  class AddressesControllerTest < ActionDispatch::IntegrationTest
    include Engine.routes.url_helpers

    def test_index
      get(addresses_path)
      assert_response(:success)
    end
  end
end
