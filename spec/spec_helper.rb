# frozen_string_literal: true

require "bundler/setup"
require "ja"

require "webmock/rspec"

require "nokogiri"
require "semantic_logger"

BUFFER = StringIO.new
Ja.logger = Logger.new(BUFFER)
Ja.logger.formatter = Proc.new { |sev, _, _, msg| "[#{sev}] #{msg}\n" }
Ja.enable_debug_logging!

module BufferHelper

  def read_buffer
    BUFFER.tap(&:rewind).read
  end

end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before do
    Thread.current[:request_id] = nil
    BUFFER.string = ""
    BUFFER.rewind
  end

  config.include(BufferHelper)

end
