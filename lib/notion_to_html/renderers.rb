# frozen_string_literal: true

require 'action_view'

# The NotionToHtml::Renderers module provides functionality for rendering Notion content
# into HTML format. It includes various helper methods from ActionView to assist
# in rendering different Notion blocks like paragraphs, headings, lists, images,
# and more.

module NotionToHtml
  module Renderers
    include ActionView::Helpers::AssetTagHelper
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper
    include ActionView::Context

    # Default CSS classes for different types of Notion blocks.
    DEFAULT_CSS_CLASSES = {
      bulleted_list_item: 'list-disc list-inside break-words',
      callout: 'flex flex-column p-4 rounded mt-4',
      code: 'border-2 p-6 rounded w-full overflow-x-auto',
      date: '',
      heading_1: 'mb-4 mt-6 text-3xl font-semibold',
      heading_2: 'mb-4 mt-6 text-2xl font-semibold',
      heading_3: 'mb-2 mt-6 text-xl font-semibold',
      image: '',
      numbered_list_item: 'list-decimal list-inside break-words',
      paragraph: '',
      quote: 'border-l-4 border-black px-5 py-1',
      video: 'w-full'
    }.freeze

    # Converts text annotations to corresponding CSS classes.
    #
    # @param annotations [Hash] the annotations hash containing keys like 'bold', 'italic', 'color', etc.
    # @return [String] a string of CSS classes.
    def annotation_to_css_class(annotations)
      classes = annotations.keys.map do |key|
        case key
        when 'strikethrough'
          'line-through' if annotations[key]
        when 'bold'
          'font-bold' if annotations[key]
        when 'code'
          'inline-code' if annotations[key]
        when 'color'
          "text-#{annotations["color"]}-600" if annotations[key] != 'default'
        else
          annotations[key] ? key : nil
        end
      end
      classes.compact.join(' ')
    end

    # Renders a rich text property into HTML.
    #
    # @param properties [Array] the rich text array containing text fragments and annotations.
    # @param options [Hash] additional options for rendering, such as CSS classes.
    # @return [String] an HTML-safe string with the rendered text.
    def text_renderer(properties, options = {})
      properties.map do |rich_text|
        classes = annotation_to_css_class(rich_text['annotations'])
        if rich_text['href']
          link_to(
            rich_text['plain_text'],
            rich_text['href'],
            class: "link #{classes} #{options[:class]}"
          )
        elsif classes.present?
          content_tag(:span, rich_text['plain_text'], class: "#{classes} #{options[:class]}")
        else
          tag.span(rich_text['plain_text'], class: options[:class])
        end
      end.join('').html_safe
    end

    # Renders a bulleted list item.
    #
    # @param rich_text_array [Array] the rich text array containing the content of the list item.
    # @param _siblings [Array] sibling list items.
    # @param children [Array] child list items.
    # @param options [Hash] additional options for rendering.
    # @return [String] an HTML-safe string with the rendered list item.
    def render_bulleted_list_item(rich_text_array, siblings, children, parent_index, options = {})
      content_tag(:ul, **options, class: css_class_for(:bulleted_list_item, options)) do
        render_list_items(:bulleted_list_item, rich_text_array, siblings, children, parent_index, options)
      end
    end

    # Renders a callout block.
    #
    # @param rich_text_array [Array] the rich text array containing the content of the callout.
    # @param icon [String] the icon to display in the callout.
    # @param options [Hash] additional options for rendering.
    # @return [String] an HTML-safe string with the rendered callout.
    def render_callout(rich_text_array, icon, options = {})
      content_tag(:div, **options, class: css_class_for(:callout, options)) do
        content = tag.span(icon, class: 'mr-4')
        content += tag.div do
          text_renderer(rich_text_array)
        end
        content
      end
    end

    # Renders a code block.
    #
    # @param rich_text_array [Array] the rich text array containing the code content.
    # @param options [Hash] additional options for rendering, including the programming language.
    # @return [String] an HTML-safe string with the rendered code block.
    def render_code(rich_text_array, options = {})
      # TODO: render captions
      content_tag(:div, data: { controller: 'highlight' }) do
        content_tag(:div, data: { highlight_target: 'source' }) do
          content_tag(:pre, **options, class: "#{css_class_for(:code, options)} language-#{options[:language]}") do
            text_renderer(rich_text_array, options)
          end
        end
      end
    end

    # Renders a date block.
    #
    # @param date [Date] the date to be rendered.
    # @param options [Hash] additional options for rendering.
    # @return [String] an HTML-safe string with the rendered date.
    def render_date(date, options = {})
      # TODO: handle end and time zone
      # date=end=, start=2023-07-13, time_zone=, id=%5BsvU, type=date
      tag.p(date.to_date.to_fs(:long), class: css_class_for(:date, options))
    end

    # Renders a heading 1 block.
    #
    # @param rich_text_array [Array] the rich text array containing the content of the heading.
    # @param options [Hash] additional options for rendering.
    # @return [String] an HTML-safe string with the rendered heading 1.
    def render_heading_1(rich_text_array, options = {})
      content_tag(:h1, **options, class: css_class_for(:heading_1, options)) do
        text_renderer(rich_text_array)
      end
    end

    # Renders a heading 2 block.
    #
    # @param rich_text_array [Array] the rich text array containing the content of the heading.
    # @param options [Hash] additional options for rendering.
    # @return [String] an HTML-safe string with the rendered heading 2.
    def render_heading_2(rich_text_array, options = {})
      content_tag(:h2, **options, class: css_class_for(:heading_2, options)) do
        text_renderer(rich_text_array)
      end
    end

    # Renders a heading 3 block.
    #
    # @param rich_text_array [Array] the rich text array containing the content of the heading.
    # @param options [Hash] additional options for rendering.
    # @return [String] an HTML-safe string with the rendered heading 3.
    def render_heading_3(rich_text_array, options = {})
      content_tag(:h3, **options, class: css_class_for(:heading_3, options)) do
        text_renderer(rich_text_array)
      end
    end

    # Renders an image block.
    #
    # @param src [String] the source URL of the image.
    # @param _expiry_time [Time] the expiration time of the image.
    # @param caption [Array] the caption text array for the image.
    # @param _type [String] the type of image (e.g., 'external', 'file').
    # @param options [Hash] additional options for rendering.
    # @return [String] an HTML-safe string with the rendered image.
    def render_image(src, _expiry_time, caption, _type, options = {})
      content_tag(:figure, **options, class: css_class_for(:image, options)) do
        content = tag.img(src: src, alt: '')
        content += tag.figcaption(text_renderer(caption))
        content
      end
    end

    # Renders a numbered list item.
    #
    # @param rich_text_array [Array] the rich text array containing the content of the list item.
    # @param siblings [Array] sibling list items.
    # @param children [Array] child list items.
    # @param options [Hash] additional options for rendering.
    # @return [String] an HTML-safe string with the rendered list item.
    def render_numbered_list_item(rich_text_array, siblings, children, parent_index, options = {})
      content_tag(:ol, **options, class: css_class_for(:numbered_list_item, options)) do
        render_list_items(:numbered_list_item, rich_text_array, siblings, children, parent_index, options)
      end
    end

    # Renders a paragraph block.
    #
    # @param rich_text_array [Array] the rich text array containing the content of the paragraph.
    # @param options [Hash] additional options for rendering.
    # @return [String] an HTML-safe string with the rendered paragraph.
    def render_paragraph(rich_text_array, options = {})
      content_tag(:p, **options, class: css_class_for(:paragraph, options)) do
        text_renderer(rich_text_array)
      end
    end

    # Renders a quote block.
    #
    # @param rich_text_array [Array] the rich text array containing the content of the quote.
    # @param options [Hash] additional options for rendering.
    # @return [String] an HTML-safe string with the rendered quote.
    def render_quote(rich_text_array, options = {})
      content_tag(:div, options) do
        content_tag(:cite) do
          content_tag(:p, **options, class: css_class_for(:quote, options)) do
            text_renderer(rich_text_array)
          end
        end
      end
    end

    # Renders a table of contents block.
    #
    # @param options [Hash] additional options for rendering.
    # @return [String] an HTML-safe string with the rendered table of contents.
    def render_table_of_contents(options = {})
      content_tag(:p, 'Table of Contents', class: css_class_for(:table_of_contents, options))
    end

    # Renders a video block.
    #
    # @param src [String] the source URL of the video.
    # @param _expiry_time [Time] the expiration time of the video.
    # @param caption [Array] the caption text array for the video.
    # @param options [Hash] additional options for rendering.
    # @return [String] an HTML-safe string with the rendered video.
    def render_video(src, _expiry_time, caption, type, options = {})
      content_tag(:figure, **options, class: css_class_for(:video, options)) do
        content = if type == 'file'
                    video_tag(src, controls: true, **options, class: css_class_for(:video, options))
                  elsif type == 'external'
                    options[:class] = "#{options[:class]} aspect-video"
                    tag.iframe(src: src, allowfullscreen: true, **options, class: css_class_for(:video, options))
                  end
        content += tag.figcaption(text_renderer(caption))
        content
      end
    end

    private

    # Determines the CSS class for a given block type.
    #
    # @param type [Symbol] the block type (e.g., :paragraph, :heading_1, etc.).
    # @param options [Hash] additional options for rendering.
    # @return [String] the CSS class for the block.
    def css_class_for(type, options)
      if options[:override_class]
        options[:class]
      else
        "#{DEFAULT_CSS_CLASSES[type]} #{options[:class]}".strip
      end
    end

    # Renders list items (bulleted or numbered).
    #
    # @param list_type [Symbol] the type of list (:bulleted_list_item or :numbered_list_item).
    # @param rich_text_array [Array] the rich text array containing the content of the list item.
    # @param siblings [Array] sibling list items.
    # @param children [Array] child list items.
    # @param options [Hash] additional options for rendering.
    # @return [String] an HTML-safe string with the rendered list items.
    def render_list_items(type, rich_text_array, siblings, children, parent_index, options = {})
      content = content_tag(:li, class: "#{options[:class]} ml-#{parent_index.to_i * 2}".strip) do
        text_renderer(rich_text_array)
      end
      if children.present?
        res = children.map do |child|
          send("render_#{type}".to_sym, child.rich_text, child.siblings, child.children, parent_index.to_i + 1, options)
        end
        content += res.join('').html_safe
      end
      if siblings.present?
        content += siblings.map do |sibling|
          render_list_items(type, sibling.rich_text, sibling.siblings, sibling.children, parent_index.to_i, options)
        end.join('').html_safe
      end
      content.html_safe
    end
  end
end
