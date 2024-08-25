# frozen_string_literal: true

require 'action_view'
require 'byebug'
require 'capybara/rspec'
require 'dotenv/load'
require 'notion-ruby-client'
require 'notion_to_html'
Dir[File.join(File.dirname(__FILE__), 'support', '**/*.rb')].sort.each { |file| require file }

NotionToHtml.configure do |config|
  config.notion_api_token = ENV['NOTION_API_TOKEN']
  config.notion_database_id = ENV['NOTION_DATABASE_ID']
end

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.include Capybara::DSL
end
