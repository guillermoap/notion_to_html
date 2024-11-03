# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NotionToHtml::Service do
  let(:service) { described_class }

  describe '#initialize' do
    it 'initializes a Notion::Client with the correct token' do
      client = service.send(:client)
      expect(client).to be_a(Notion::Client)
      expect(client.token).to eq(NotionToHtml.config.notion_api_token)
    end
  end

  describe '#default_query' do
    context 'when no name or description or slug or tag is provided' do
      it 'returns the default query' do
        expected_query = [
          {
            property: 'public',
            checkbox: { equals: true }
          }
        ]
        expect(service.default_query).to eq(expected_query)
      end
    end

    context 'when a slug is provided' do
      it 'includes the slug in the query' do
        slug = 'example-slug'
        expected_query = [
          {
            property: 'public',
            checkbox: { equals: true }
          },
          {
            property: 'slug',
            rich_text: { equals: slug }
          }
        ]
        expect(service.default_query(slug: slug)).to eq(expected_query)
      end
    end

    context 'when a name is provided' do
      it 'includes the name in the query' do
        name = 'example-name'
        expected_query = [
          {
            property: 'public',
            checkbox: { equals: true }
          },
          {
            property: 'name',
            rich_text: { contains: name }
          }
        ]
        expect(service.default_query(name: name)).to eq(expected_query)
      end
    end

    context 'when a description is provided' do
      it 'includes the description in the query' do
        description = 'example-description'
        expected_query = [
          {
            property: 'public',
            checkbox: { equals: true }
          },
          {
            property: 'description',
            rich_text: { contains: description }
          }
        ]
        expect(service.default_query(description: description)).to eq(expected_query)
      end
    end

    context 'when a tag is provided' do
      it 'includes the tag in the query' do
        tag = 'example-tag'
        expected_query = [
          {
            property: 'public',
            checkbox: { equals: true }
          },
          {
            property: 'tags',
            multi_select: { contains: tag }
          }
        ]
        expect(service.default_query(tag: tag)).to eq(expected_query)
      end
    end

    context 'when both slug and tag are provided' do
      it 'includes both the slug and tag in the query' do
        slug = 'example-slug'
        tag = 'example-tag'
        expected_query = [
          {
            property: 'public',
            checkbox: { equals: true }
          },
          {
            property: 'slug',
            rich_text: { equals: slug }
          },
          {
            property: 'tags',
            multi_select: { contains: tag }
          }
        ]
        expect(service.default_query(slug: slug, tag: tag)).to eq(expected_query)
      end
    end

    context 'when both name and description are provided' do
      it 'includes both the name and description in the query' do
        name = 'example-name'
        description = 'example-description'
        expected_query = [
          {
            property: 'public',
            checkbox: { equals: true }
          },
          {
            property: 'name',
            rich_text: { contains: name }
          },
          {
            property: 'description',
            rich_text: { contains: description }
          }
        ]
        expect(service.default_query(name: name, description: description)).to eq(expected_query)
      end
    end
  end

  describe '#default_sorting' do
    it 'returns the default sorting hash' do
      expected_sorting = { property: 'published', direction: 'descending' }
      expect(service.default_sorting).to eq(expected_sorting)
    end
  end

  describe '#get_pages' do
    subject { service.get_pages(tag: 'test', page_size: page_size) }

    let(:page_size) { 10 }

    it 'queries the Notion database and returns pages', vcr: { cassette_name: 'get_pages' } do
      expect(subject).to be_an(Array)
      expect(subject.first).to be_a(NotionToHtml::BasePage)
    end
  end

  describe '#get_page' do
    subject { service.get_page(id) }

    let(:id) { service.get_pages(tag: 'test', page_size: 10).first.id }

    it 'returns a NotionToHtml::Page with the correct base_page and base_blocks',
      vcr: { cassette_name: 'get_page' } do
      expect(subject).to be_a(NotionToHtml::Page)
      expect(subject.metadata).to be_a(NotionToHtml::BasePage)
      expect(subject.blocks).to be_an(Array)
    end
  end

  describe '#get_blocks' do
    subject { service.get_blocks(id) }

    let(:id) { service.get_pages(tag: 'test', page_size: 10).first.id }

    it 'returns an array of blocks', vcr: { cassette_name: 'get_blocks' } do
      expect(subject).to be_an(Array)
      expect(subject.first).to be_a(NotionToHtml::BaseBlock)
    end

    it 'correctly handles lists of blocks with siblings', vcr: { cassette_name: 'get_blocks' } do
      results = subject
                .filter { _1.type == 'bulleted_list_item' }
                .map { _1.children.count }
      expect(results).to match([1, 0, 0, 2, 0])
    end

    context 'when an image block is not expired' do
      before do
        allow(service).to receive(:refresh_image?).and_return(false)
        allow(service).to receive(:refresh_block).and_call_original
      end

      it 'does not refresh the block for the image', vcr: { cassette_name: 'get_blocks' } do
        subject
        expect(service).not_to have_received(:refresh_block)
      end
    end

    context 'when an image block has expired' do
      before do
        allow(ActiveSupport::TimeWithZone).to receive(:past?).and_return(true)
        allow(service).to receive(:refresh_block).and_call_original
      end

      it 'refreshes the block for the image ', vcr: { cassette_name: 'get_blocks' } do
        subject
        expect(service).to have_received(:refresh_block).once
      end
    end
  end

  describe '#refresh_image?' do
    let(:data) { { 'type' => 'image', 'image' => { 'type' => 'file', 'file' => { 'expiry_time' => expiry_time } } } }
    let(:expired_data) do
      { 'type' => 'image', 'image' => { 'type' => 'file', 'file' => { 'expiry_time' => (Time.now + 1.week).iso8601 } } }
    end
    let(:expiry_time) { (Time.now - 1.hour).iso8601 }

    it 'returns true if the image has expired' do
      expect(service.refresh_image?(data)).to be true
    end

    it 'returns false if the image has not expired' do
      expect(service.refresh_image?(expired_data)).to be false
    end

    it 'returns false for non-image types' do
      data['type'] = 'text'
      expect(service.refresh_image?(data)).to be false
    end
  end
end
