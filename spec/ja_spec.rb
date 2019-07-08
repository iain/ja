# frozen_string_literal: true

RSpec.describe Ja do

  let(:url) { "http://example.com/widgets" }

  def stubbed_request(verb = :any, url = self.url)
    stub_request(verb, url)
  end

  describe "url" do

    it "gets combines with the path" do
      req = stub_request(:get, "http://example.com/widgets")
      Ja.api(url: "http://example.com").get("widgets")
      expect(req).to have_been_made
    end

    it "doesn't overdo slashes" do
      req = stub_request(:get, "http://example.com/widgets")
      Ja.api(url: "http://example.com/").get("/widgets")
      expect(req).to have_been_made
    end

    it "doesn't reset paths" do
      req = stub_request(:get, "http://example.com/sprockets/widgets")
      Ja.api(url: "http://example.com/sprockets").get("/widgets")
      expect(req).to have_been_made
    end

  end

  describe "client" do

    it "uses the provided client" do
      req = stubbed_request
      header = { "X-My-Header" => "my-value" }
      Ja.api(client: HTTP.headers(header)).get(url)
      expect(req.with(headers: header)).to have_been_made
    end

  end

  describe "automatic headers" do

    it "sends X-Request-Id header" do
      Thread.current[:request_id] = "my-request-id"
      request = stub_request(:any, url)
      Ja.api.get(url)
      expect(request.with(headers: { "X-Request-Id" => "my-request-id" })).to have_been_made
    end

  end

  describe "logging" do

    it "logs successful responses with INFO level message" do
      logger = double(:logger, info: true)
      stubbed_request.to_return(status: 200)
      Ja.api(logger: logger).get(url)
      regex = /\A\(\d+\.\d+ms\) GET #{url} responded with 200 OK\z/
      expect(logger).to have_received(:info).with(a_string_matching(regex))
    end

    it "logs redirects with WARN level message" do
      logger = double(:logger, warn: true)
      stubbed_request.to_return(status: 300)
      Ja.api(logger: logger).get(url)
      regex = /\A\(\d+\.\d+ms\) GET #{url} responded with 300 Multiple Choices\z/
      expect(logger).to have_received(:warn).with(a_string_matching(regex))
    end

    it "logs client errors with ERROR level message" do
      logger = double(:logger, error: true)
      stubbed_request.to_return(status: 400)
      Ja.api(logger: logger).get(url)
      regex = /\A\(\d+\.\d+ms\) GET #{url} responded with 400 Bad Request\z/
      expect(logger).to have_received(:error).with(a_string_matching(regex))
    end

    it "logs server errors with ERROR level message" do
      logger = double(:logger, error: true)
      stubbed_request.to_return(status: 500)
      Ja.api(logger: logger).get(url)
      regex = /\A\(\d+\.\d+ms\) GET #{url} responded with 500 Internal Server Error\z/
      expect(logger).to have_received(:error).with(a_string_matching(regex))
    end

    it "logs for SemanticLogger" do
      logger = SemanticLogger["RSpec"]
      allow(logger).to receive(:info)
      stubbed_request.to_return(status: 200)
      Ja.api(logger: logger).get(url)
      expect(logger).to have_received(:info).with(
        message: "GET #{url} responded with 200 OK",
        duration: a_kind_of(Float),
        payload: {
          verb:    "GET",
          url:     url,
          status:  200,
          reason:  "OK",
        }
      )
    end

  end

  describe "errors" do

    it "responds normally when status < 400" do
      stubbed_request.to_return(status: 200)
      expect(Ja.api.get(url)).to be_a(HTTP::Response)
    end

    it "raises with pretty JSON response body" do
      body = { foo: "bar" }
      stubbed_request.to_return(status: 422, body: body.to_json, headers: { content_type: "application/json" })
      expect {
        Ja.api.get!(url)
      }.to raise_error(
        Ja::Error::UnprocessableEntity,
        %(GET #{url} responded with 422 Unprocessable Entity\n\n#{JSON.pretty_generate(body)})
      )
    end

    it "raises with pretty XML in response body" do
      body = "<root><tag>value</tag></root>"
      stubbed_request.to_return(status: 500, body: body, headers: { content_type: "application/xml" })
      expect {
        Ja.api.get!(url)
      }.to raise_error(
        Ja::Error::InternalServerError,
        %(GET #{url} responded with 500 Internal Server Error\n\n<root>\n  <tag>value</tag>\n</root>)
      )
    end

    it "raises with pretty HTML in the response body" do
      body = %(<p><a href="#">oops</a></p>)
      stubbed_request.to_return(status: 418, body: body, headers: { content_type: "text/html" })
      expect {
        Ja.api.get!(url)
      }.to raise_error(
        Ja::Error::ResponseError,
        %(GET #{url} responded with 418\n\n<p>\n  <a href="#">oops</a>\n</p>)
      )
    end

    it "doesn't touch text/plain" do
      body = %(some text)
      stubbed_request.to_return(status: 503, body: body, headers: { content_type: "text/plain" })
      expect {
        Ja.api.get!(url)
      }.to raise_error(
        Ja::Error::ServiceUnavailable,
        %(GET #{url} responded with 503 Service Unavailable\n\n#{body})
      )
    end

    it "omits other content types" do
      stubbed_request.to_return(status: 400, body: "X", headers: { content_type: "image/jpeg" })
      expect {
        Ja.api.get!(url)
      }.to raise_error(
        Ja::Error::BadRequest,
        %(GET #{url} responded with 400 Bad Request\n\n«body ommitted: unsupported Content-Type: "image/jpeg"»)
      )
    end

  end

  describe "debug logging" do

    it "prints the log" do
      body = { foo: "bar" }
      stubbed_request.to_return(status: 200, body: body.to_json, headers: { content_type: "application/json" })
      Ja.api.get(url)
      log = <<~LOG
        [DEBUG] Sending GET to "http://example.com/widgets"

        GET /widgets HTTP/1.1
        Connection: close
        Host: example.com
        User-Agent: http.rb/#{HTTP::VERSION}

        «body ommitted: unsupported Content-Type: nil»


        [DEBUG] Response from GET to "http://example.com/widgets"

        HTTP/1.1 200 OK
        Content-Type: application/json

        {
          "foo": "bar"
        }

      LOG

      body = read_buffer
      colors = ["\e[36m", "\e[35m", "\e[0m"]
      colors.each do |color|
        body = body.gsub(color, "")
      end

      expect(body).to start_with(log)
    end

    it "handles no content with JSON" do
      stubbed_request.to_return(status: 204, body: nil, headers: { content_type: "application/json" })
      Ja.api.get(url)
    end

  end

end
