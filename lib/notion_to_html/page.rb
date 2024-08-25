# frozen_string_literal: true

# The NotionToHtml::Page class represents a Notion page, containing both the metadata and blocks associated with the page.
# This class integrates metadata and blocks, providing methods to format and render the page's content.

module NotionToHtml
  class Page
    include NotionToHtml::Renderers

    # @return [BasePage] The metadata of the page, encapsulating details like title, description, and published date.
    attr_reader :metadata
    # @return [Array<BaseBlock>] The blocks of the page, representing the content sections.
    attr_reader :blocks

    # Delegate methods to metadata for easy access to formatted title, description, and published date.
    delegate :formatted_title, to: :metadata
    delegate :formatted_description, to: :metadata
    delegate :formatted_published_at, to: :metadata

    # Initializes a new Page object.
    # @param base_page [BasePage] The metadata of the page.
    # @param base_blocks [Array<BaseBlock>] The blocks of the page.
    def initialize(base_page, base_blocks)
      @metadata = base_page
      @blocks = base_blocks
    end

    # Formats and renders the blocks of the page.
    # @param options [Hash] Additional options for rendering the blocks.
    # @return [Array<String>] The rendered blocks as an array of HTML strings.
    def formatted_blocks(options = {})
      @blocks.map { |block| block.render(options) }
    end
  end
end
