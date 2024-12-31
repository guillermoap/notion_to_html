# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotionToHtml::BaseBlock do
  let(:created_time) { '2024-01-01T00:00:00.000Z' }
  let(:last_edited_time) { '2024-01-02T00:00:00.000Z' }
  let(:base_data) do
    {
      'id' => 'block_id',
      'created_time' => created_time,
      'last_edited_time' => last_edited_time,
      'created_by' => { 'id' => 'user1' },
      'last_edited_by' => { 'id' => 'user2' },
      'parent' => { 'page_id' => 'page1' },
      'archived' => false,
      'has_children' => false
    }
  end

  describe '#initialize' do
    it 'initializes with basic block attributes' do
      data = base_data.merge({
        'type' => 'paragraph',
        'paragraph' => {
          'rich_text' => []
        }
      })

      block = described_class.new(data)

      expect(block.id).to eq('block_id')
      expect(block.created_time).to eq(created_time)
      expect(block.last_edited_time).to eq(last_edited_time)
      expect(block.created_by).to eq({ 'id' => 'user1' })
      expect(block.last_edited_by).to eq({ 'id' => 'user2' })
      expect(block.parent).to eq({ 'page_id' => 'page1' })
      expect(block.archived).to be false
      expect(block.has_children).to be false
      expect(block.children).to eq([])
      expect(block.siblings).to eq([])
      expect(block.type).to eq('paragraph')
      expect(block.properties).to eq({ 'rich_text' => [] })
    end
  end

  describe 'dynamic methods for block options' do
    let(:block) { described_class.new(base_data.merge({ 'type' => 'paragraph', 'paragraph' => {} })) }
    let(:options) do
      {
        paragraph: { class: 'custom-para', data: { test: 'value' } },
        heading_1: { class: 'main-heading', data: { level: '1' } },
        code: { class: 'code-block', data: { language: 'ruby' } }
      }
    end

    NotionToHtml::BaseBlock::BLOCK_TYPES.each do |block_type|
      describe "#class_for_#{block_type}" do
        it "returns class for #{block_type}" do
          result = block.send("class_for_#{block_type}", options)
          expected = options[block_type]&.dig(:class)
          expect(result).to eq(expected)
        end
      end

      describe "#data_for_#{block_type}" do
        it "returns data for #{block_type}" do
          result = block.send("data_for_#{block_type}", options)
          expected = options[block_type]&.dig(:data)
          expect(result).to eq(expected)
        end
      end
    end
  end

  describe '#rich_text' do
    it 'returns empty array when no rich_text is present' do
      data = base_data.merge({
        'type' => 'paragraph',
        'paragraph' => {}
      })
      block = described_class.new(data)
      expect(block.rich_text).to eq([])
    end

    it 'returns rich_text array when present' do
      rich_text_data = [{ 'type' => 'text', 'text' => { 'content' => 'Hello' } }]
      data = base_data.merge({
        'type' => 'paragraph',
        'paragraph' => { 'rich_text' => rich_text_data }
      })
      block = described_class.new(data)
      expect(block.rich_text).to eq(rich_text_data)
    end
  end

  describe '#icon' do
    it 'returns empty array when no icon content is present' do
      data = base_data.merge({
        'type' => 'callout',
        'callout' => { 'icon' => { 'type' => 'emoji', 'emoji' => nil } }
      })
      block = described_class.new(data)
      expect(block.icon).to eq([])
    end

    it 'returns icon content when present' do
      data = base_data.merge({
        'type' => 'callout',
        'callout' => { 'icon' => { 'type' => 'emoji', 'emoji' => '📌' } }
      })
      block = described_class.new(data)
      expect(block.icon).to eq('📌')
    end
  end

  describe '#multi_media' do
    context 'with file type' do
      let(:file_data) do
        base_data.merge({
          'type' => 'image',
          'image' => {
            'type' => 'file',
            'file' => {
              'url' => 'https://example.com/file.jpg',
              'expiry_time' => '2024-12-31T00:00:00.000Z'
            },
            'caption' => [{ 'text' => { 'content' => 'A caption' } }]
          }
        })
      end

      it 'returns file information array' do
        block = described_class.new(file_data)
        url, expiry_time, caption, type = block.multi_media
        expect(url).to eq('https://example.com/file.jpg')
        expect(expiry_time).to eq('2024-12-31T00:00:00.000Z')
        expect(caption).to eq([{ 'text' => { 'content' => 'A caption' } }])
        expect(type).to eq('file')
      end
    end

    context 'with external type' do
      let(:external_data) do
        base_data.merge({
          'type' => 'image',
          'image' => {
            'type' => 'external',
            'external' => {
              'url' => 'https://example.com/external.jpg'
            },
            'caption' => []
          }
        })
      end

      it 'returns external information array' do
        block = described_class.new(external_data)
        url, expiry_time, caption, type = block.multi_media
        expect(url).to eq('https://example.com/external.jpg')
        expect(expiry_time).to be_nil
        expect(caption).to eq([])
        expect(type).to eq('external')
      end
    end

    context 'with direct url' do
      let(:direct_url_data) do
        base_data.merge({
          'type' => 'image',
          'image' => {
            'url' => 'https://example.com/direct.jpg',
            'caption' => []
          }
        })
      end

      it 'returns direct url information array' do
        block = described_class.new(direct_url_data)
        url, expiry_time, caption, type = block.multi_media
        expect(url).to eq('https://example.com/direct.jpg')
        expect(expiry_time).to be_nil
        expect(caption).to eq([])
        expect(type).to be_nil
      end
    end
  end
end
