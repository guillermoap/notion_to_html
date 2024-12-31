# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotionToHtml::Renderers do
  include NotionToHtml::Renderers

  describe '#annotation_to_css_class' do
    context 'when annotations are default' do
      let(:annotations) do
        { 'bold' => false, 'italic' => false, 'strikethrough' => false, 'underline' => false, 'code' => false,
          'color' => 'default' }
      end

      it 'returns an empty string' do
        expect(annotation_to_css_class(annotations)).to eq('')
      end
    end

    context 'when annotations include bold' do
      let(:annotations) do
        { 'bold' => true, 'italic' => false, 'strikethrough' => false, 'underline' => false, 'code' => false,
          'color' => 'default' }
      end

      it 'returns the font-bold class' do
        expect(annotation_to_css_class(annotations)).to eq('font-bold')
      end
    end

    context 'when annotations include italic' do
      let(:annotations) do
        { 'bold' => false, 'italic' => true, 'strikethrough' => false, 'underline' => false, 'code' => false,
          'color' => 'default' }
      end

      it 'returns the italic class' do
        expect(annotation_to_css_class(annotations)).to eq('italic')
      end
    end

    context 'when annotations include underline' do
      let(:annotations) do
        { 'bold' => false, 'italic' => false, 'strikethrough' => false, 'underline' => true, 'code' => false,
          'color' => 'default' }
      end

      it 'returns the underline class' do
        expect(annotation_to_css_class(annotations)).to eq('underline')
      end
    end

    context 'when annotations include color' do
      let(:annotations) do
        { 'bold' => false, 'italic' => false, 'strikethrough' => false, 'underline' => false, 'code' => false,
          'color' => 'red' }
      end

      it 'returns the color class' do
        expect(annotation_to_css_class(annotations)).to eq('text-red-600')
      end
    end

    context 'when annotations include multiple styles' do
      let(:annotations) do
        { 'bold' => true, 'italic' => true, 'strikethrough' => true, 'underline' => true, 'code' => true,
          'color' => 'blue' }
      end

      it 'returns the combined class names' do
        expect(annotation_to_css_class(annotations)).to eq('font-bold italic line-through underline inline-code text-blue-600')
      end
    end
  end

  describe '#text_renderer' do
    context 'when rich text has no annotations' do
      let(:rich_text) do
        [{ 'plain_text' => 'Hello, world!',
           'annotations' => { 'bold' => false, 'italic' => false, 'strikethrough' => false, 'underline' => false, 'code' => false,
                              'color' => 'default' } }]
      end

      it 'renders plain text without additional classes' do
        html = text_renderer(rich_text)
        rendered_html = Capybara.string(html)

        expect(rendered_html).to have_selector('span', text: 'Hello, world!')
        expect(rendered_html).not_to have_selector('span.font-bold')
      end
    end

    context 'when rich text has bold annotation' do
      let(:rich_text) do
        [{ 'plain_text' => 'Bold text',
           'annotations' => { 'bold' => true, 'italic' => false, 'strikethrough' => false, 'underline' => false, 'code' => false,
                              'color' => 'default' } }]
      end

      it 'renders text with bold class' do
        html = text_renderer(rich_text)
        rendered_html = Capybara.string(html)

        expect(rendered_html).to have_selector('span.font-bold', text: 'Bold text')
      end
    end

    context 'when rich text has color annotation' do
      let(:rich_text) do
        [{ 'plain_text' => 'Colored text',
           'annotations' => { 'bold' => false, 'italic' => false, 'strikethrough' => false, 'underline' => false, 'code' => false,
                              'color' => 'green' } }]
      end

      it 'renders text with color class' do
        html = text_renderer(rich_text)
        rendered_html = Capybara.string(html)

        expect(rendered_html).to have_selector('span.text-green-600', text: 'Colored text')
      end
    end

    context 'when rich text includes a hyperlink' do
      let(:rich_text) do
        [{ 'plain_text' => 'Link text',
           'annotations' => { 'bold' => false, 'italic' => false, 'strikethrough' => false, 'underline' => false, 'code' => false, 'color' => 'default' }, 'href' => 'https://example.com' }]
      end

      it 'renders a link with the correct href' do
        html = text_renderer(rich_text)
        rendered_html = Capybara.string(html)

        expect(rendered_html).to have_selector('a[href="https://example.com"]', text: 'Link text')
      end
    end
  end

  describe '#render_bulleted_list_item' do
    let(:rich_text) { [{ 'plain_text' => 'List item', 'annotations' => {} }] }
    let(:default_class) { described_class::DEFAULT_CSS_CLASSES[:bulleted_list_item].gsub(' ', '.') }

    it 'renders a bulleted list item with rich text' do
      html = render_bulleted_list_item(rich_text, [], [], 0)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("ul.#{default_class} li", text: 'List item')
    end

    it 'concatenates default and custom classes' do
      html = render_bulleted_list_item(rich_text, [], [], 0, class: 'custom-class')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("ul.#{default_class} li.custom-class", text: 'List item')
    end

    it 'overrides the default class' do
      html = render_bulleted_list_item(rich_text, [], [], 0, class: 'custom-class', override_class: true)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('ul li.custom-class', text: 'List item')
      expect(rendered_html).not_to have_selector("ul.#{default_class} li", text: 'List item')
    end

    it 'renders data attributes' do
      html = render_bulleted_list_item(rich_text, [], [], 0, data: { controller: 'test' })

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('ul[data-controller="test"]')
    end
  end

  describe '#render_code' do
    let(:rich_text) { [{ 'plain_text' => 'puts "Hello, world!"', 'annotations' => { 'code' => true } }] }
    let(:default_class) { described_class::DEFAULT_CSS_CLASSES[:code].gsub(' ', '.') }

    it 'renders a code block with rich text' do
      html = render_code(rich_text, language: 'ruby')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("pre.#{default_class}.language-ruby", text: 'puts "Hello, world!"')
    end

    it 'concatenates default and custom classes' do
      html = render_code(rich_text, class: 'custom-class')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("pre.#{default_class}.custom-class", text: 'puts "Hello, world!"')
    end

    it 'overrides the default class' do
      html = render_code(rich_text, class: 'custom-class', override_class: true)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('pre.custom-class', text: 'puts "Hello, world!"')
      expect(rendered_html).not_to have_selector("pre.#{default_class}", text: 'puts "Hello, world!"')
    end

    it 'renders data attributes' do
      html = render_code(rich_text, data: { controller: 'test' })

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('pre[data-controller="test"]')
    end
  end

  describe '#render_callout' do
    let(:rich_text) { [{ 'plain_text' => 'A callout', 'annotations' => {} }] }
    let(:default_class) { described_class::DEFAULT_CSS_CLASSES[:callout].gsub(' ', '.') }

    it 'renders a callout with rich text and icon' do
      html = render_callout(rich_text, '⚠️')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("div.#{default_class}", text: 'A callout')
      expect(rendered_html).to have_selector('span.mr-4', text: '⚠️')
    end

    it 'concatenates custom CSS classes with default classes' do
      options = { class: 'custom-callout-class' }
      html = render_callout(rich_text, '⚠️', options)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("div.#{default_class}.custom-callout-class", text: 'A callout')
    end

    it 'overrides default CSS classes when custom classes are provided' do
      options = { class: 'custom-class flex p-8' }
      html = render_callout(rich_text, '⚠️', options)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('div.custom-class.flex.p-8', text: 'A callout')
    end

    it 'renders data attributes' do
      options = { data: { controller: 'test' } }
      html = render_callout(rich_text, '⚠️', options)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('div[data-controller="test"]')
    end
  end

  describe '#render_date' do
    let(:date) { Date.new(2023, 7, 13) }
    let(:default_class) { described_class::DEFAULT_CSS_CLASSES[:date].gsub(' ', '.') }

    it 'renders a date' do
      html = render_date(date)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("p#{default_class.blank? ? "" : "."}#{default_class}",
        text: 'July 13, 2023')
    end

    it 'concatenates custom CSS classes with default classes' do
      options = { class: 'custom-date-class' }
      html = render_date(date, options)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("p#{default_class.blank? ? "" : "."}#{default_class}.custom-date-class",
        text: 'July 13, 2023')
    end

    it 'overrides default CSS classes when custom classes are provided' do
      options = { class: 'custom-class text-blue-500' }
      html = render_date(date, options)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('p.custom-class.text-blue-500', text: 'July 13, 2023')
    end

    it 'renders data attributes' do
      html = render_date(date, data: { controller: 'test' })

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('p[data-controller="test"]')
    end
  end

  describe '#render_heading_1' do
    let(:rich_text) { [{ 'plain_text' => 'Heading 1', 'annotations' => { 'bold' => true } }] }
    let(:default_class) { described_class::DEFAULT_CSS_CLASSES[:heading_1].gsub(' ', '.') }

    it 'renders a heading 1 with rich text' do
      html = render_heading_1(rich_text)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("h1.#{default_class}", text: 'Heading 1')
    end

    it 'concatenates default and custom classes' do
      html = render_heading_1(rich_text, class: 'custom-class')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("h1.#{default_class}.custom-class", text: 'Heading 1')
    end

    it 'overrides the default class' do
      html = render_heading_1(rich_text, class: 'custom-class', override_class: true)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('h1.custom-class', text: 'Heading 1')
      expect(rendered_html).not_to have_selector("h1.#{default_class}", text: 'Heading 1')
    end

    it 'renders data attributes' do
      html = render_heading_1(rich_text, data: { controller: 'test' })

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('h1[data-controller="test"]')
    end
  end

  describe '#render_heading_2' do
    let(:rich_text) { [{ 'plain_text' => 'Heading 2', 'annotations' => { 'italic' => true } }] }
    let(:default_class) { described_class::DEFAULT_CSS_CLASSES[:heading_2].gsub(' ', '.') }

    it 'renders a heading 2 with rich text' do
      html = render_heading_2(rich_text)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("h2.#{default_class}", text: 'Heading 2')
    end

    it 'concatenates default and custom classes' do
      html = render_heading_2(rich_text, class: 'custom-class')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("h2.#{default_class}.custom-class", text: 'Heading 2')
    end

    it 'overrides the default class' do
      html = render_heading_2(rich_text, class: 'custom-class', override_class: true)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('h2.custom-class', text: 'Heading 2')
      expect(rendered_html).not_to have_selector("h2.#{default_class}", text: 'Heading 2')
    end

    it 'renders data attributes' do
      html = render_heading_2(rich_text, data: { controller: 'test' })

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('h2[data-controller="test"]')
    end
  end

  describe '#render_heading_3' do
    let(:rich_text) { [{ 'plain_text' => 'Heading 3', 'annotations' => { 'underline' => true } }] }
    let(:default_class) { described_class::DEFAULT_CSS_CLASSES[:heading_3].gsub(' ', '.') }

    it 'renders a heading 3 with rich text' do
      html = render_heading_3(rich_text)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("h3.#{default_class}", text: 'Heading 3')
    end

    it 'concatenates default and custom classes' do
      html = render_heading_3(rich_text, class: 'custom-class')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("h3.#{default_class}.custom-class", text: 'Heading 3')
    end

    it 'overrides the default class' do
      html = render_heading_3(rich_text, class: 'custom-class', override_class: true)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('h3.custom-class', text: 'Heading 3')
      expect(rendered_html).not_to have_selector("h3.#{default_class}", text: 'Heading 3')
    end

    it 'renders data attributes' do
      html = render_heading_3(rich_text, data: { controller: 'test' })

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('h3[data-controller="test"]')
    end
  end

  describe '#render_image' do
    let(:caption) { [{ 'plain_text' => 'An image caption', 'annotations' => {} }] }
    let(:default_class) { described_class::DEFAULT_CSS_CLASSES[:image].gsub(' ', '.') }

    it 'renders an image with a caption' do
      html = render_image('image_src.jpg', nil, caption, 'file')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("figure#{default_class.blank? ? "" : "."}#{default_class}")
      expect(rendered_html).to have_selector('img[src="image_src.jpg"]')
      expect(rendered_html).to have_selector('figcaption', text: 'An image caption')
    end

    it 'concatenates default and custom classes' do
      html = render_image('image_src.jpg', nil, caption, 'file', class: 'custom-class')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("figure#{default_class.blank? ? "" : "."}#{default_class}.custom-class")
    end

    it 'overrides the default class' do
      html = render_image('image_src.jpg', nil, caption, 'file', class: 'custom-class', override_class: true)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('figure.custom-class')
      # TODO: When/if image has a default class add expect to test that it doesn't render when overriden
    end

    it 'renders data attributes' do
      html = render_image('image_src.jpg', nil, caption, 'file', data: { controller: 'test' })

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('figure[data-controller="test"]')
    end
  end

  describe '#render_numbered_list_item' do
    let(:rich_text) { [{ 'plain_text' => 'List item', 'annotations' => {} }] }
    let(:default_class) { described_class::DEFAULT_CSS_CLASSES[:numbered_list_item].gsub(' ', '.') }

    it 'renders a numbered list item with rich text' do
      html = render_numbered_list_item(rich_text, [], [], 0)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("ol.#{default_class} li", text: 'List item')
    end

    it 'concatenates default and custom classes' do
      html = render_numbered_list_item(rich_text, [], [], 0, class: 'custom-class')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("ol.#{default_class} li.custom-class", text: 'List item')
    end

    it 'overrides the default class' do
      html = render_numbered_list_item(rich_text, [], [], 0, class: 'custom-class', override_class: true)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('ol li.custom-class', text: 'List item')
      expect(rendered_html).not_to have_selector("ol.#{default_class} li", text: 'List item')
    end

    it 'renders data attributes' do
      html = render_numbered_list_item(rich_text, [], [], 0, data: { controller: 'test' })

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('ol[data-controller="test"]')
    end
  end

  describe '#render_paragraph' do
    let(:rich_text) { [{ 'plain_text' => 'Hello, world!', 'annotations' => { 'bold' => true } }] }
    let(:default_class) { described_class::DEFAULT_CSS_CLASSES[:paragraph].gsub(' ', '.') }

    it 'renders a paragraph with rich text' do
      html = render_paragraph(rich_text)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("p#{default_class.blank? ? "" : "."}#{default_class}")
      expect(rendered_html).to have_selector('span.font-bold', text: 'Hello, world!')
    end

    it 'concatenates default and custom classes' do
      html = render_paragraph(rich_text, class: 'custom-class')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("p#{default_class.blank? ? "" : "."}#{default_class}.custom-class")
    end

    it 'overrides the default class' do
      html = render_paragraph(rich_text, class: 'custom-class', override_class: true)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('p.custom-class')
      # TODO: When/if paragraph has a default class add expect to test that it doesn't render when overriden
    end

    it 'renders data attributes' do
      html = render_paragraph(rich_text, data: { controller: 'test' })

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('p[data-controller="test"]')
    end
  end

  describe '#render_quote' do
    let(:rich_text) { [{ 'plain_text' => 'A quote', 'annotations' => {} }] }
    let(:default_class) { described_class::DEFAULT_CSS_CLASSES[:quote].gsub(' ', '.') }

    it 'renders a quote with rich text' do
      html = render_quote(rich_text)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("cite p.#{default_class}", text: 'A quote')
    end

    it 'concatenates default and custom classes' do
      html = render_quote(rich_text, class: 'custom-quote-class')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("cite p.#{default_class}.custom-quote-class", text: 'A quote')
    end

    it 'overrides the default class' do
      html = render_quote(rich_text, class: 'custom-quote-class', override_class: true)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('cite p.custom-quote-class', text: 'A quote')
      expect(rendered_html).not_to have_selector("cite p.#{default_class}", text: 'A quote')
    end

    it 'renders data attributes' do
      html = render_quote(rich_text, data: { controller: 'test' })

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('cite p[data-controller="test"]')
    end
  end

  describe '#render_video' do
    let(:caption) { [{ 'plain_text' => 'A video caption', 'annotations' => {} }] }
    let(:default_class) { described_class::DEFAULT_CSS_CLASSES[:video].gsub(' ', '.') }

    it 'renders a video with a caption' do
      html = render_video('video_src.mp4', nil, caption, 'file')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("figure#{default_class.blank? ? "" : "."}#{default_class}")
      expect(rendered_html).to have_selector('figcaption', text: 'A video caption')

      video_element = rendered_html.find('video')
      expect(video_element[:src]).to match(/video_src.mp4/)
      expect(video_element[:controls]).to eq('controls')
    end

    it 'concatenates default and custom classes' do
      html = render_video('video_src.mp4', nil, caption, 'file', class: 'custom-class')

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector("figure#{default_class.blank? ? "" : "."}#{default_class}.custom-class")
    end

    it 'overrides the default class' do
      html = render_video('video_src.mp4', nil, caption, 'file', class: 'custom-class', override_class: true)

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('figure.custom-class')
      # TODO: When/if video has a default class add expect to test that it doesn't render when overriden
    end

    it 'renders data attributes' do
      html = render_video('video_src.mp4', nil, caption, 'file', data: { controller: 'test' })

      rendered_html = Capybara.string(html)

      expect(rendered_html).to have_selector('figure[data-controller="test"]')
    end
  end
end
