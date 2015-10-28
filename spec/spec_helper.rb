ENV['EVERCAM_ENV'] ||= 'test'

require 'evercam_misc'
require 'sequel'
Sequel::Model.db = Sequel.connect(Evercam::Config[:database])

require 'bundler'
Bundler.require(:default, :test)

# code coverage
SimpleCov.start do
  add_filter '/spec/'
end

require_relative './matchers'

def require_app(name)
  require_relative "../app/#{name}"
end

require_relative "../lib/actors"

LogJam.configure({
 :loggers => [{ :default => true, :file => 'STDOUT', :level => ENV['LOG'] || 'FATAL' }]
})

RSpec.configure do |c|
  c.filter_run :focus => true
  c.filter_run_excluding skip: true
  c.run_all_when_everything_filtered = true
  c.mock_framework = :mocha
  c.fail_fast = true if ENV['FAIL_FAST']

  c.after(:suite) do
    DatabaseCleaner.clean_with :truncation, except: %w[spatial_ref_sys]
  end

  c.before :each do
    Typhoeus::Expectation.clear
    Evercam::Services::dalli_cache.flush_all
    #Stub external requests
    stub_request(:get, /.*api.intercom.io.*/).
      to_return(:status => 200, :body => "", :headers => {})

    WebMock.disable_net_connect!(:allow_localhost => true)
  end
end

# fake out sidekiq redis
require 'sidekiq/testing'
Sidekiq::Testing.fake!

# Stubbed requests
require 'webmock/rspec'

# Set up Airbrake.
require 'airbrake'
Airbrake.configure do |config|
  config.api_key = Evercam::Config[:airbrake][:api_key]
  config.environment_name = (ENV['RACK_ENV'] || 'test')
end

