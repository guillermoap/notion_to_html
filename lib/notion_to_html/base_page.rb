# frozen_string_literal: true

# The NotionToHtml::BasePage class represents a Notion page, handling its attributes and rendering.
# This class processes the raw data of a page fetched from the Notion API and makes
# it accessible through various attributes. It also provides methods to render formatted
# output for the page's title, description, and published date.

module NotionToHtml
  class BasePage
    include NotionToHtml::Renderers

    # @return [String] the ID of the page.
    attr_reader :id
    # @return [String] the creation timestamp of the page.
    attr_reader :created_time
    # @return [String] the last edited timestamp of the page.
    attr_reader :last_edited_time
    # @return [String] the user who created the page.
    attr_reader :created_by
    # @return [String] the user who last edited the page.
    attr_reader :last_edited_by
    # @return [Hash, nil] the cover image of the page.
    attr_reader :cover
    # @return [Hash, nil] the icon of the page.
    attr_reader :icon
    # @return [Hash] the parent of the page (e.g., database ID).
    attr_reader :parent
    # @return [Boolean] whether the page is archived.
    attr_reader :archived
    # @return [Hash] the properties of the page.
    attr_reader :properties
    # @return [String, nil] the publication date of the page.
    attr_reader :published_at
    # @return [Array<Hash>, nil] the tags associated with the page.
    attr_reader :tags
    # @return [Array<Hash>, nil] the title of the page.
    attr_reader :title
    # @return [String, nil] the slug of the page.
    attr_reader :slug
    # @return [Array<Hash>, nil] the description of the page.
    attr_reader :description
    # @return [String] the URL of the page.
    attr_reader :url

    # Initializes a new BasePage object.
    # @param data [Hash] The raw data of the page from the Notion API.
    def initialize(data)
      @id = data['id']
      @created_time = data['created_time']
      @last_edited_time = data['last_edited_time']
      @created_by = data['created_by'] # TODO: handle user object
      @last_edited_by = data['last_edited_by'] # TODO: handle user object
      @cover = data['cover'] # TODO: handle external type
      @icon = data['icon'] # TODO: handle emoji type
      @parent = data['parent'] # TODO: handle database_id type
      @archived = data['archived']
      @properties = data['properties'] # TODO: handle properties object
      process_properties
      @url = data['url']
    end

    # Renders the formatted title of the page.
    # @param options [Hash] Additional options for rendering the title.
    # @return [String] The formatted title.
    def formatted_title(options = {})
      render_heading_1(@title, options)
    end

    # Renders the formatted description of the page.
    # @param options [Hash] Additional options for rendering the description.
    # @return [String] The formatted description.
    def formatted_description(options = {})
      render_paragraph(@description, options)
    end

    # Renders the formatted publication date of the page.
    # @param options [Hash] Additional options for rendering the publication date.
    # @return [String] The formatted publication date.
    def formatted_published_at(options = {})
      render_date(@published_at, options)
    end

    private

    # Processes the properties of the page and assigns them to the relevant attributes.
    # @return [void]
    def process_properties
      @tags = @properties['tags']
      @title = @properties.dig('name', 'title')
      @slug = @properties['slug']
      @published_at = @properties.dig('published', 'date', 'start')
      @description = @properties.dig('description', 'rich_text')
    end
  end
end
