require 'fluent_plugin_filter_parse_postfix/version'
require 'postfix_status_line'
require 'time'

module Fluent
  class ParsePostfixFilter < Filter
    Plugin.register_filter('parse_postfix', self)

    config_param :key,                 :string,  :default => 'message'
    config_param :mask,                :bool,    :default => true
    config_param :use_log_time ,       :bool,    :default => false
    config_param :include_hash,        :bool,    :default => false
    config_param :salt,                :string,  :default => nil
    config_param :sha_algorithm,       :integer, :default => nil
    config_param :parse_header_checks, :bool,    :default => false

    def filter(tag, time, record)
      line = record[@key]
      return record unless line

      options = {mask: @mask, hash: @include_hash, salt: @salt, parse_time: @use_log_time, sha_algorithm: @sha_algorithm}

      if @parse_header_checks
        parsed = PostfixStatusLine.parse_header_checks(line, options)
      else
        parsed = PostfixStatusLine.parse(line, options)
      end

      unless parsed
        log.warn "cannot parse a postfix log: #{line}"
        return record
      end

      if @use_log_time and parsed['epoch']
        time = parsed.delete('epoch')
      end

      parsed
    rescue => e
      log.warn "failed to parse a postfix log: #{line}", :error_class => e.class, :error => e.message
      log.warn_backtrace
      record
    end
  end
end
