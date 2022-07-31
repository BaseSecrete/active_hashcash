module ActiveHashcash
  class Stamp
    attr_reader :version, :bits, :date, :resource, :extension, :rand, :counter

    def self.parse(string)
      args = string.split(":")
      new(args[0], args[1], args[2], args[3], args[4], args[5], args[6])
    end

    def self.mint(resource, options = {})
      new(
        options[:version] || 1,
        options[:bits] || ActiveHashcash.bits,
        options[:date] || Date.today.strftime("%y%m%d"),
        resource,
        options[:ext],
        options[:rand] || SecureRandom.alphanumeric(16),
        options[:counter] || 0).work
    end

    def initialize(version, bits, date, resource, extension, rand, counter)
      @version = version
      @bits = bits.to_i
      @date = date.respond_to?(:strftime) ? date.strftime("%y%m%d") : date
      @resource = resource
      @extension = extension
      @rand = rand
      @counter = counter
    end

    def valid?
      Digest::SHA1.hexdigest(to_s).hex >> (160-bits) == 0
    end

    def to_s
      [version, bits, date, resource, extension, rand, counter].join(":")
    end

    def parse_date
      Date.strptime(date, "%y%m%d")
    end

    def work
      @counter += 1 until valid?
      self
    end
  end
end
