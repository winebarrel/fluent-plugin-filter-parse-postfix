require 'fluent_plugin_filter_parse_postfix/version'
require 'postfix_status_line'

module Fluent
  class ParsePostfixFilter < Filter
    Plugin.register_filter('parse_postfix', self)

    config_param :key,  :string, :default => 'message'
    config_param :mask, :bool,   :default => true

    def filter_stream(tag, es)
      result_es = Fluent::MultiEventStream.new

      es.each do |time, record|
        parse_postfix(time, record, result_es)
      end

      result_es
    rescue => e
      log.warn e.message
      log.warn e.backtrace.join(', ')
    end

    private

    def parse_postfix(time, record, result_es)
      line = record[@key]
      return unless line

      line = PostfixStatusLine.parse(line, @mask)
      return unless line

      result_es.add(time, line)
    end
  end
end
