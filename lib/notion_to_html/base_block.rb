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
    BLOCK_TYPES = %i[
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

    BLOCK_TYPES.each do |block|
      define_method("class_for_#{block}") { |options| options.dig(block, :class) }
      define_method("data_for_#{block}") { |options| options.dig(block, :data) }
    end

    # Renders the block based on its type.
    # @param options [Hash] Additional options for rendering the block.
    # @return [String] The rendered block as HTML.
    def render(options = {})
      render_method = RENDERERS[@type]
      return 'Unsupported block' unless render_method

      send(render_method, build_render_options(options))
    end

    private

    # Maps block types to their corresponding render methods
    RENDERERS = {
      'paragraph' => :render_paragraph_block,
      'heading_1' => :render_heading_1_block,
      'heading_2' => :render_heading_2_block,
      'heading_3' => :render_heading_3_block,
      'table_of_contents' => :render_table_of_contents_block,
      'bulleted_list_item' => :render_bulleted_list_item_block,
      'numbered_list_item' => :render_numbered_list_item_block,
      'quote' => :render_quote_block,
      'callout' => :render_callout_block,
      'code' => :render_code_block,
      'image' => :render_image_block,
      'embed' => :render_image_block,
      'video' => :render_video_block
    }.freeze

    # Builds render options for a block type
    # @param options [Hash] The original options hash
    # @return [Hash] Processed options for rendering
    def build_render_options(options)
      {
        class: send("class_for_#{@type}", options),
        data: send("data_for_#{@type}", options),
        **options.dig(@type)&.except(:class, :data).to_h
      }
    end

    def render_paragraph_block(options)
      render_paragraph(rich_text, **options)
    end

    def render_heading_1_block(options)
      render_heading_1(rich_text, **options)
    end

    def render_heading_2_block(options)
      render_heading_2(rich_text, **options)
    end

    def render_heading_3_block(options)
      render_heading_3(rich_text, **options)
    end

    def render_table_of_contents_block(_options)
      render_table_of_contents
    end

    def render_bulleted_list_item_block(options)
      render_bulleted_list_item(rich_text, @siblings, @children, 0, **options)
    end

    def render_numbered_list_item_block(options)
      render_numbered_list_item(rich_text, @siblings, @children, 0, **options)
    end

    def render_quote_block(options)
      render_quote(rich_text, **options)
    end

    def render_callout_block(options)
      render_callout(rich_text, icon, **options)
    end

    def render_code_block(options)
      render_code(rich_text, **options.merge(language: @properties['language']))
    end

    def render_image_block(options)
      render_image(*multi_media, **options)
    end

    def render_video_block(options)
      render_video(*multi_media, **options)
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
