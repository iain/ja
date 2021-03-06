# frozen_string_literal: true

module Ja
  class API

    include Methods

    LOG_LINE = "%{verb} %{url} responded with %{status} %{reason}"

    def initialize(client:   HTTP,
                   url:      nil,
                   logger:   Ja.logger,
                   log_line: LOG_LINE)

      @client = client
      @logger = logger
      @log_line = log_line
      @url = url
      if url
        uri = URI.parse(url)
        if uri.user || uri.password
          @client = @client.basic_auth(user: uri.user, pass: uri.password)
          uri.user = nil
          uri.password = nil
          @url = uri.to_s
        end
      end
      @semantic_logging = Ja.enable_semantic_logging? || (defined?(SemanticLogger) && logger.is_a?(SemanticLogger::Logger))
    end

    attr_reader :client, :logger, :log_line, :url

    def request(verb, uri, options = {})
      full_uri = full_url(uri)
      start_time = now
      client_with_request_id = client.headers("X-Request-Id" => Thread.current[:request_id])
      response = client_with_request_id.request(verb, full_uri, options)
      log_response(response, start_time, verb, full_uri, options)
      response
    end

    def request!(verb, uri, options = {})
      response = request(verb, uri, options)
      if (100..399).cover?(response.status)
        response
      else
        fail Error.to_exception(verb, full_url(uri), response)
      end
    end

    def full_url(path)
      if url
        File.join(url, path)
      else
        path
      end
    end

    private

    def log_response(response, start_time, verb, uri, _options)
      duration = ((now - start_time) * 1000.0).round(3)

      log_level = case response.status
                  when 100..299
                    :info
                  when 300..399
                    :warn
                  else
                    :error
                  end

      payload = {
        verb:    verb.to_s.upcase,
        url:     uri.to_s,
        status:  response.status.to_i,
        reason:  response.status.reason.to_s,
      }

      message = log_line % payload

      if @semantic_logging
        logger.public_send(log_level, message: message, duration: duration, payload: payload)
      else
        logger.public_send(log_level, "(%.2fms) %s" % [ duration, message ])
      end
    end

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

  end
end
