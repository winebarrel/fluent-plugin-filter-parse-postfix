require 'fluent_plugin_filter_parse_postfix/version'
require 'postfix_status_line'

module Fluent
  class ParsePostfixFilter < Filter
    Plugin.register_filter('parse_postfix', self)

    config_param :key,          :string, :default => 'message'
    config_param :mask,         :bool,   :default => true
    config_param :use_log_time, :bool,   :default => true

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

      parsed = PostfixStatusLine.parse(line, @mask)

      unless parsed
        log.warn "Could not parse a postfix log: #{line}"
        return
      end

      if @use_log_time
        time = parsed['time'] || time
      end

      result_es.add(time, parsed)
    end
  end
end
