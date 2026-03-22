#!/usr/bin/env ruby
# frozen_string_literal: true

# Benchmark: SHA-1 vs SHA-256 for hashcash stamp minting & verification
#
# Usage:
#   cd active_hashcash
#   bundle exec ruby benchmark/benchmark.rb

require "benchmark"
require "digest"
require "securerandom"

BITS_LEVELS = [ 16, 18, 20 ]
RESOURCE = "benchmark.example.com"
DATE_STR = Time.now.strftime("%y%m%d")
VERIFY_ITERATIONS = 100_000

def build_stamp(ext: "")
  version = 1
  bits = 20
  rand = SecureRandom.alphanumeric(16)
  counter = 0
  "#{version}:#{bits}:#{DATE_STR}:#{RESOURCE}:#{ext}:#{rand}:#{counter}"
end

# --- Part 1: Raw digest throughput ---

puts "=" * 70
puts "Part 1: Raw digest throughput (#{VERIFY_ITERATIONS} iterations)"
puts "=" * 70
puts

stamp_str = build_stamp

Benchmark.bm(12) do |x|
  x.report("SHA-1:")   { VERIFY_ITERATIONS.times { Digest::SHA1.hexdigest(stamp_str) } }
  x.report("SHA-256:") { VERIFY_ITERATIONS.times { Digest::SHA256.hexdigest(stamp_str) } }
end

puts

# --- Part 2: Stamp minting (proof-of-work) ---

puts "=" * 70
puts "Part 2: Stamp minting speed (finding valid proof-of-work)"
puts "=" * 70
puts

def mint_sha1(resource, bits)
  version = 1
  date = Time.now.strftime("%y%m%d")
  rand = SecureRandom.alphanumeric(16)
  counter = 0

  loop do
    stamp = "#{version}:#{bits}:#{date}:#{resource}::#{rand}:#{counter}"
    break [ stamp, counter ] if Digest::SHA1.hexdigest(stamp).hex >> (160 - bits) == 0
    counter += 1
  end
end

def mint_sha256(resource, bits)
  version = 1
  date = Time.now.strftime("%y%m%d")
  rand = SecureRandom.alphanumeric(16)
  counter = 0

  loop do
    stamp = "#{version}:#{bits}:#{date}:#{resource}:sha256:#{rand}:#{counter}"
    break [ stamp, counter ] if Digest::SHA256.hexdigest(stamp).hex >> (256 - bits) == 0
    counter += 1
  end
end

ROUNDS = 3

BITS_LEVELS.each do |bits|
  puts "-" * 70
  puts "Bits: #{bits} (expected ~#{2**bits} attempts on average)"
  puts "-" * 70

  sha1_times = []
  sha256_times = []
  sha1_counters = []
  sha256_counters = []

  ROUNDS.times do |i|
    t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    _, counter = mint_sha1(RESOURCE, bits)
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t
    sha1_times << elapsed
    sha1_counters << counter

    t = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    _, counter = mint_sha256(RESOURCE, bits)
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t
    sha256_times << elapsed
    sha256_counters << counter
  end

  sha1_avg = sha1_times.sum / ROUNDS
  sha256_avg = sha256_times.sum / ROUNDS
  sha1_hps = sha1_counters.zip(sha1_times).map { |c, t| (c / t).round }.sum / ROUNDS
  sha256_hps = sha256_counters.zip(sha256_times).map { |c, t| (c / t).round }.sum / ROUNDS

  puts "  SHA-1:   avg %.3fs across %d rounds (%s hashes/s)" % [ sha1_avg, ROUNDS, sha1_hps.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse ]
  puts "  SHA-256: avg %.3fs across %d rounds (%s hashes/s)" % [ sha256_avg, ROUNDS, sha256_hps.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse ]
  ratio = sha256_hps.to_f / sha1_hps
  puts "  SHA-256 throughput vs SHA-1: %.2fx" % ratio
  puts
end
