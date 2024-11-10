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

  # @!attribute [rw] notion_timeout
  #   @return [Integer] The number of seconds to wait for a response from the Notion API before timing out.
  #   @example
  #     config.notion_timeout = 60 # Wait up to 60 seconds for API responses
  setting :notion_timeout, default: 30

  # @!attribute [rw] notion_default_page_size
  #   @return [Integer] The default number of records to return per page when making paginated requests.
  #   @example
  #     config.notion_default_page_size = 50 # Return 50 records per page
  setting :notion_default_page_size, default: 100

  # @!attribute [rw] notion_default_max_retries
  #   @return [Integer] The maximum number of times to retry failed API requests.
  #   @example
  #     config.notion_default_max_retries = 3 # Retry failed requests up to 3 times
  setting :notion_default_max_retries, default: 5

  # @!attribute [rw] notion_default_retry_after
  #   @return [Integer] The number of seconds to wait between retry attempts for failed API requests.
  #   @example
  #     config.notion_default_retry_after = 5 # Wait 5 seconds between retries
  setting :notion_default_retry_after, default: 10

  # @!attribute [rw] cache_store
  #   @return [ActiveSupport::Cache::Store] The cache store used to cache responses from the Notion API.
  #   @default ActiveSupport::Cache::MemoryStore.new
  setting :cache_store, default: ActiveSupport::Cache::MemoryStore.new
end
