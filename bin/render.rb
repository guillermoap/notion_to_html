#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'byebug'
require 'erb'
require 'launchy'
require 'dotenv/load'
require 'notion_to_html' # Assuming NotionToHtml gem is required

NotionToHtml.configure do |config|
  config.notion_api_token = ENV['NOTION_API_TOKEN']
  config.notion_database_id = ENV['NOTION_DATABASE_ID']
end

module NotionToHtml
  class Service
    class << self
      def default_query(tag: nil, slug: nil)
        [
          {
            property: 'public',
            checkbox: {
              equals: false
            }
          },
          {
            property: 'tags',
            multi_select: {
              contains: 'test'
            }
          }
        ]
      end
    end
  end
end

pages = NotionToHtml::Service.get_pages

get_pages_template = ERB.new <<~EOF
  <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <script src="https://cdn.tailwindcss.com"></script>
    </head>
    <body>
      <section class="container mx-auto my-24 w-full">
        <h1 class="text-2xl">Default rendering</h1>
        <p class="text-lg mb-12">Click the preview to see how a default page renders</p>
        <% pages.each do |page| %>
          <a href="./get_page.html" class="inline-block mb-8 pb-4">
            <div>
              <%= page.formatted_published_at %>
              <%= page.formatted_title %>
              <%= page.formatted_description %>
            </div>
          </a>
        <% end %>
      </section>
    </body>
  </html>
EOF
rendered_content = get_pages_template.result(binding)

File.open('./examples/get_pages.html', 'w') do |file|
  file.write(rendered_content)
end
Launchy.open('./examples/get_pages.html')

page = NotionToHtml::Service.get_page(pages.first.id)
get_page_template = ERB.new <<~EOF
  <!doctype html>
  <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <script src="https://cdn.tailwindcss.com"></script>
    </head>
    <body>
      <section class="container mx-auto my-24 w-full">
        <%= page.formatted_title %>
        <%= page.formatted_published_at %>
        <% page.formatted_blocks.each do |block| %>
          <%= block %>
        <% end %>
      </section>
    </body>
  </html>
EOF
rendered_content = get_page_template.result(binding)

File.open('./examples/get_page.html', 'w') do |file|
  file.write(rendered_content)
end

puts 'Rendered content is opened in your default web browser.'
