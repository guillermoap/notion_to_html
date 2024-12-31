# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotionToHtml::Page do
  let(:formatted_title) { 'My Page Title' }
  let(:formatted_description) { 'Page description' }
  let(:formatted_published_at) { '2024-01-01' }

  let(:base_page) do
    instance_double(
      'NotionToHtml::BasePage',
      formatted_title: formatted_title,
      formatted_description: formatted_description,
      formatted_published_at: formatted_published_at
    )
  end

  let(:block1) { instance_double('NotionToHtml::BaseBlock') }
  let(:block2) { instance_double('NotionToHtml::BaseBlock') }
  let(:base_blocks) { [block1, block2] }

  subject(:page) { described_class.new(base_page, base_blocks) }

  describe '#initialize' do
    it 'sets metadata and blocks' do
      expect(page.metadata).to eq(base_page)
      expect(page.blocks).to eq(base_blocks)
    end
  end

  describe 'delegated methods' do
    it 'delegates formatted_title to metadata' do
      expect(page.formatted_title).to eq(formatted_title)
    end

    it 'delegates formatted_description to metadata' do
      expect(page.formatted_description).to eq(formatted_description)
    end

    it 'delegates formatted_published_at to metadata' do
      expect(page.formatted_published_at).to eq(formatted_published_at)
    end
  end

  describe '#formatted_blocks' do
    let(:rendering_options) do
      {
        paragraph: { class: 'custom-paragraph' },
        image: { class: 'custom-image', data: { controller: 'test' } }
      }
    end

    before do
      allow(block1).to receive(:render).and_return('<p>Block 1 content</p>')
      allow(block2).to receive(:render).and_return('<h1>Block 2 content</h1>')
    end

    it 'renders all blocks with default options' do
      rendered_blocks = page.formatted_blocks
      expect(rendered_blocks).to be_an(Array)
      expect(rendered_blocks.size).to eq(2)
      expect(block1).to have_received(:render).with({})
      expect(block2).to have_received(:render).with({})
    end

    it 'renders all blocks with custom options' do
      rendered_blocks = page.formatted_blocks(rendering_options)
      expect(rendered_blocks).to be_an(Array)
      expect(rendered_blocks.size).to eq(2)
      expect(block1).to have_received(:render).with(rendering_options)
      expect(block2).to have_received(:render).with(rendering_options)
    end

    it 'preserves block order in rendered output' do
      rendered_blocks = page.formatted_blocks
      expect(rendered_blocks[0]).to eq('<p>Block 1 content</p>')
      expect(rendered_blocks[1]).to eq('<h1>Block 2 content</h1>')
    end

    context 'with empty blocks array' do
      let(:base_blocks) { [] }

      it 'returns an empty array' do
        expect(page.formatted_blocks).to eq([])
      end
    end

    context 'when a block raises an error during rendering' do
      before do
        allow(block1).to receive(:render).and_raise(StandardError, 'Rendering failed')
      end

      it 'allows the error to propagate' do
        expect { page.formatted_blocks }.to raise_error(StandardError, 'Rendering failed')
      end
    end
  end
end
