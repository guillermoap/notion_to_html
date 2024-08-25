# frozen_string_literal: true

# The NotionToHtml::BaseBlock class represents a block in a Notion page, handling its attributes and rendering.
# This class processes the raw data of a block fetched from the Notion API and makes
# it accessible through various attributes. It also provides methods to render formatted
# output for different block types like paragraphs, headings, lists, quotes, and media.

module NotionToHtml
  class BaseBlock
    include NotionToHtml::Renderers

    # @return [String] the ID of the block.
    attr_reader :id
    # @return [String] the creation timestamp of the block.
    attr_reader :created_time
    # @return [String] the last edited timestamp of the block.
    attr_reader :last_edited_time
    # @return [String] the user who created the block.
    attr_reader :created_by
    # @return [String] the user who last edited the block.
    attr_reader :last_edited_by
    # @return [Hash] the parent of the block (e.g., page ID).
    attr_reader :parent
    # @return [Boolean] whether the block is archived.
    attr_reader :archived
    # @return [Boolean] whether the block has children.
    attr_reader :has_children
    # @return [String] the type of the block (e.g., 'paragraph', 'heading_1').
    attr_reader :type
    # @return [Hash] the properties of the block, specific to its type.
    attr_reader :properties

    # @return [Array<BaseBlock>] the children blocks of this block.
    attr_accessor :children
    # @return [Array<BaseBlock>] the sibling blocks of this block.
    attr_accessor :siblings

    # The list of block types that can be rendered.
    BLOCK_TYPES = %w[
      paragraph
      heading_1
      heading_2
      heading_3
      bulleted_list_item
      numbered_list_item
      quote
      callout
      code
      image
      embed
      video
    ].freeze

    # Initializes a new BaseBlock object.
    # @param data [Hash] The raw data of the block from the Notion API.
    def initialize(data)
      @id = data['id']
      @created_time = data['created_time']
      @last_edited_time = data['last_edited_time']
      @created_by = data['created_by'] # TODO: handle user object
      @last_edited_by = data['last_edited_by'] # TODO: handle user object
      @parent = data['parent'] # TODO: handle page_id type
      @archived = data['archived']
      @has_children = data['has_children']
      @children = []
      @siblings = []
      @type = data['type']
      @properties = data[@type]
    end

    # Renders the block based on its type.
    # @param options [Hash] Additional options for rendering the block.
    # @return [String] The rendered block as HTML.
    def render(options = {})
      case @type
      when 'paragraph'
        render_paragraph(rich_text, class: options[:paragraph])
      when 'heading_1'
        render_heading_1(rich_text, class: options[:heading_1])
      when 'heading_2'
        render_heading_2(rich_text, class: options[:heading_2])
      when 'heading_3'
        render_heading_3(rich_text, class: options[:heading_3])
      when 'table_of_contents'
        render_table_of_contents
      when 'bulleted_list_item'
        render_bulleted_list_item(rich_text, @siblings, @children, 0, class: options[:bulleted_list_item])
      when 'numbered_list_item'
        render_numbered_list_item(rich_text, @siblings, @children, 0, class: options[:numbered_list_item])
      when 'quote'
        render_quote(rich_text, class: options[:quote])
      when 'callout'
        render_callout(rich_text, icon, class: options[:callout])
      when 'code'
        render_code(rich_text, class: options[:code], language: @properties['language'])
      when 'image', 'embed'
        render_image(*multi_media, class: options[:image])
      when 'video'
        render_video(*multi_media, class: options[:video])
      else
        'Unsupported block'
      end
    end

    # Retrieves the rich text content of the block.
    # @return [Array<Hash>] The rich text content.
    def rich_text
      @properties['rich_text'] || []
    end

    # Retrieves the icon associated with the block.
    # @return [Array<Hash>] The icon data.
    def icon
      icon = @properties['icon']
      @properties['icon'][icon['type']] || []
    end

    # Retrieves the multimedia data for the block.
    # @return [Array] The multimedia data (URL, expiry time, caption, type).
    def multi_media
      case @properties['type']
      when 'file'
        [@properties.dig('file', 'url'), @properties.dig('file', 'expiry_time'), @properties['caption'], 'file']
      when 'external'
        [@properties.dig('external', 'url'), nil, @properties['caption'], 'external']
      else
        [@properties['url'], nil, @properties['caption'], nil]
      end
    end
  end
end
