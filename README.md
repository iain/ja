# Ja

A wrapper around the [http.rb](https://github.com/httprb/http) gem.

The features so far:

* Logging (with multiple levels, depending on the response status)
* Automatically raising errors
* Automatically adding the `X-Request-Id` header (from `Thread.current[:request_id]`)

## Usage

Without options, you will get simple logging as a result:

``` ruby
response = Ja.api.get("http://example.com/widgets")
[INFO] (1.12ms) GET http://example.com/widgets responded with 200 OK
```

You can customize this, for instance by setting part of the url:

``` ruby
my_service = Ja.api(url: "http://my-service.com")
respoonse = my_service.get("widgets")
```


Or by setting your own HTTP options:

``` ruby
client = HTTP.basic_auth(user: "alice", pass: "secret")
my_authenticated_service = Ja.api(client: client)
my_authenticated_service.get("my-private-widgets")
```

### Raising errors

If you want to automatically raise an error when a request fails, you can use `get!`, `post!`, etc instead of the version without a bang.

``` ruby
my_service = Ja.api(url: "http://my-service.com")

# raises no error:
my_service.get("not-found")

# raises Ja::Error::NotFound
my_service.get!("not-found")
```

Most HTTP status have their own error class. They inherit from `Ja::Error::ClientError` for 4xx responses and `Ja::Error::ServerError` for 5xx responses. All inherit from `Ja::Error`.

### Logging

Requests are automatically logged. We detect Rails.logger, Hanami.logger or SemanticLogger by default.

If the request is successful (i.e. 2xx), the log level is `info`. If the response is a redirect (i.e. 3xx), it will use the `warn` log level. For client errors (4xx) and server errors (5xx) the `error` log level is used.

You can set a logger per service:

``` ruby
my_service = Ja.api(logger: Logger.new("log/my-service.log"))
```

Or configure a logger globally (it will automatically recognize Rails, Hanami and SemanticLogger):

```
Ja.logger = Logger.new("log/http.log")
```

To log the full request and full response, we need to do some monkey patching, so it is disabled by default. To enable it, call `Ja.enable_debug_logging!`. You may want to do this only for development/test but not on production, because it might mess with streaming responses. Full request logging will always log in `debug` log level and will always use the globally configered logger.

### Request ID

One very helpful way to manage multiple services is to pass along a "request id". If you tag your logs with that value, you can use a centralized logging service to track a request as it propagates through your fleet of microservices.

You are responsible for making sure it gets set, but if you set `Thread.current[:request_id]` it will automatically be added as a header.

Here's an example in Rack middleware:

``` ruby
class RequestIdMiddleware

  def initialize(app)
    @app = app
  end

  def call(env)
    request_id = (env["HTTP_X_REQUEST_ID"] || SecureRandom.uuid.delete("-"))
    Thread.current[:request_id] = request_id
    @app.call(env)
  end

end
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ja'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ja

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/iain/ja.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
