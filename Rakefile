# frozen_string_literal: true

require "bundler/gem_tasks"
require 'rake/testtask'

task default: :test

Rake::TestTask.new(:test) do |test|
  test.pattern = "test/**/*_test.rb"
  test.libs << "lib" << "test"
  test.verbose = true
end
