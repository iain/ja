# frozen_string_literal: true

module Ja
  module DebugLogger

    def perform(req, options)
      Ja.logger.debug {
        lines = ["Sending #{req.verb.to_s.upcase} to #{req.uri.to_s.inspect}"]
        lines << "\e[36m"
        lines << req.headline
        lines += req.headers.map { |key, value| "#{key}: #{value}" }
        body = Ja.format_body(req.headers) {
          buffer = ""
          req.body.each { |chunk| buffer << chunk }
          buffer
        }
        "#{lines.join("\n")}\n\n#{body}\n\e[0m\n"
      }

      res = super

      Ja.logger.debug {
        lines = ["Response from #{req.verb.to_s.upcase} to #{req.uri.to_s.inspect}"]
        lines << "\e[35m"
        lines << "HTTP/#{res.instance_variable_get(:@version)} #{res.status}"
        lines += res.headers.map { |key, value| "#{key}: #{value}" }
        body = Ja.format_body(res.headers) { res.body.to_s }
        "#{lines.join("\n")}\n\n#{body}\n\e[0m\n"
      }

      res
    end

  end
end
