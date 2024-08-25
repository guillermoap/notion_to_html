# frozen_string_literal: true

require 'active_support/all'
require 'notion_to_html/renderers'
require 'notion_to_html/base_block'
require 'notion_to_html/base_page'
require 'notion_to_html/page'
require 'notion_to_html/service'
require 'dry-configurable'

module NotionToHtml
  extend Dry::Configurable

  # @!attribute [rw] notion_api_token
  #   @return [String] The API token used to authenticate requests to the Notion API.
  setting :notion_api_token

  # @!attribute [rw] notion_database_id
  #   @return [String] The database ID in Notion that the module will interact with.
  setting :notion_database_id

  # @!attribute [rw] cache_store
  #   @return [ActiveSupport::Cache::Store] The cache store used to cache responses from the Notion API.
  #   @default ActiveSupport::Cache::MemoryStore.new
  setting :cache_store, default: ActiveSupport::Cache::MemoryStore.new
end
