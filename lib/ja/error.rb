module Ja
  class Error < StandardError

    def self.to_exception(verb, uri, response)
      Error.fetch_error_class(response.status).new(verb, uri, response)
    end

    def self.fetch_error_class(status)
      const_get(HTTP::Response::Status::REASONS.fetch(status, "ResponseError").gsub(/\W/, ""))
    end

    attr_reader :response, :verb, :uri

    def initialize(verb, uri, response)
      @response = response
      @verb = verb
      @uri = uri

      @headline = "%{verb} %{url} responded with %{status}" % {
        status:  response.status,
        verb:    verb.to_s.upcase,
        url:     uri.to_s,
      }

      @response_body = Ja.format_body(response.headers) { response.body.to_s }

      @message = @response_body ? "#{@headline}\n\n#{@response_body}" : @headline
    end

    attr_reader :message, :response_body, :headline

    alias_method :to_s, :message

    def status
      response.status
    end

    # Base class for all errors
    ResponseError = Class.new(Error)

    # Base class for errors in the 4xx range
    ClientError = Class.new(ResponseError)

    # Base class for errors in the 5xx range
    ServerError = Class.new(ResponseError)

    HTTP::Response::Status::REASONS.each do |status, name|
      parent = status >= 500 ? ServerError : ClientError
      const_set(name.gsub(/\W/, ""), Class.new(parent))
    end

  end
end
