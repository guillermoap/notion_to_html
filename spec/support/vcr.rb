# frozen_string_literal: true

require 'vcr'
require 'webmock/rspec'

VCR.configure do |config|
  config.default_cassette_options = { record: :new_episodes }
  config.cassette_library_dir = 'spec/fixtures/notion_to_html'
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.before_record do |i|
    if ENV.key?('NOTION_API_TOKEN')
      i.request.headers['Authorization'].first.gsub!(ENV['NOTION_API_TOKEN'], '<NOTION_API_TOKEN>')
    end
  end
end
