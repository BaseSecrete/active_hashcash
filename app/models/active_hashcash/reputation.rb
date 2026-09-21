# frozen_string_literal: true

module ActiveHashcash
  module Reputation
    def self.scores(ip)
      address = IPv4Address.scores(ip)
      range = IPv4Range.scores(ip)
      {
        abuse: [address[:abuse], range[:abuse]].max,
        anonymous: [address[:anonymous], range[:anonymous]].max,
        attack: [address[:attack], range[:attack]].max
      }
    end
  end
end
