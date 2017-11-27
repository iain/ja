require "http"
require "logger"

require "ja/version"

require "ja/methods"
require "ja/error"
require "ja/api"
require "ja/debug_logger"

module Ja

  def self.logger
    @logger ||= default_logger
  end

  def self.logger=(logger)
    @logger = logger
  end

  def self.api(*args, &block)
    API.new(*args, &block)
  end

  def self.default_logger
    if defined?(Rails) && Rails.logger
      Rails.logger
    elsif defined?(Hanami) && Hanami.logger
      Hanami.logger
    elsif defined?(SemanticLogger)
      SemanticLogger[self]
    else
      Logger.new($stdout)
    end
  end

  # TODO detect streaming
  def self.format_body(headers, &body)
    mime_type = parse_mime_type(headers)
    case mime_type
    when /\bjson$/
      str = body.call
      begin
        JSON.pretty_generate(JSON.parse(str))
      rescue JSON::ParserError
        str
      end
    when /\bhtml$/, /\bxml$/
      str = body.call
      if defined?(Nokogiri)
        Nokogiri::XML(str).to_xhtml.chomp
      else
        str
      end
    when /\bplain$/
      body.call
    else
      "«body ommitted: unsupported Content-Type: #{mime_type.inspect}»"
    end
  end

  def self.parse_mime_type(headers)
    HTTP::ContentType.parse(headers[HTTP::Headers::CONTENT_TYPE]).mime_type
  end

  def self.enable_debug_logging!
    return if HTTP::Client.ancestors.include?(DebugLogger)
    HTTP::Client.prepend(DebugLogger)
  end

end
