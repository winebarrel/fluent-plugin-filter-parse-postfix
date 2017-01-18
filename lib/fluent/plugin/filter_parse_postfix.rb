require 'fluent_plugin_filter_parse_postfix/version'
require 'postfix_status_line'
require 'time'

module Fluent
  class ParsePostfixFilter < Filter
    Plugin.register_filter('parse_postfix', self)

    config_param :key,           :string,  :default => 'message'
    config_param :mask,          :bool,    :default => true
    config_param :use_log_time,  :bool,    :default => false
    config_param :include_hash,  :bool,    :default => false
    config_param :salt,          :string,  :default => nil
    config_param :sha_algorithm, :integer, :default => nil

    def filter_stream(tag, es)
      result_es = Fluent::MultiEventStream.new

      es.each do |time, record|
        parse_postfix(time, record, result_es)
      end

      result_es
    end

    private

    def parse_postfix(time, record, result_es)
      line = record[@key]
      return unless line

      parsed = PostfixStatusLine.parse(
        line,
        mask: @mask, hash: @include_hash, salt: @salt, parse_time: @use_log_time, sha_algorithm: @sha_algorithm)

      unless parsed
        log.warn "cannot parse a postfix log: #{line}"
        return
      end

      if @use_log_time and parsed['epoch']
        time = parsed.delete('epoch')
      end

      result_es.add(time, parsed)
    rescue => e
      log.warn "failed to parse a postfix log: #{line}", :error_class => e.class, :error => e.message
      log.warn_backtrace
    end
  end
end
