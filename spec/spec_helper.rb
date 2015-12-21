$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'fluent/test'
require 'fluent/plugin/filter_parse_postfix'
require 'time'
require 'timecop'

# Disable Test::Unit
module Test::Unit::RunCount; def run(*); end; end

RSpec.configure do |config|
  config.before(:all) do
    Fluent::Test.setup
  end
end

def create_driver(options = {})
  fluentd_conf = <<-EOS
type parse_postfix
  EOS

  options.each do |key, value|
    fluentd_conf << <<-EOS
#{key} #{value}
    EOS
  end

  tag = options[:tag] || 'test.default'
  Fluent::Test::FilterTestDriver.new(Fluent::ParsePostfixFilter, tag).configure(fluentd_conf)
end
