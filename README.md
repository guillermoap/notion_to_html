# NotionToHtml

NotionToHtml is a Ruby gem designed to integrate Notion with Ruby applications. It provides a set of tools for rendering Notion pages and blocks, allowing you to maintain a database of pages in Notion while rendering them real time in you application with ease.

Now you can use Notion to publish your pages directly to your Ruby web page with one click.

## Table of Contents

- [NotionToHtml](#notiontohtml)
- [Table of Contents](#table-of-contents)
- [About](#about)
- [Installation](#installation)
- [Dependencies](#dependencies)
- [Setup](#setup)
- [Configuration](#configuration)
- [Usage](#usage)
  - [Rendering](#rendering)
    - [Pages](#pages)
    - [Specific Page](#specific-page)
    - [Customizing styles](#customizing-styles)
    - [Overriding default styles](#overriding-default-styles)
    - [Adding data options](#adding-data-options)
  - [Querying](#querying)
    - [Filtering](#filtering)
    - [Sorting](#sorting)
- [Examples](#examples)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)
- [Code of Conduct](#code-of-conduct)

## About

NotionToHtml allows you to seamlessly integrate Notion pages and blocks into your Ruby application. It provides a set of renderers for various Notion block types, including headings, paragraphs, images, and more. With NotionToHtml, you can easily display and format Notion content in your views.

You just need to create a database in Notion, integrate it and start writing!

## Installation

Add the gem to your application's Gemfile:
```bash
bundle add notion_to_html
```
Or install it yourself as:
```bash
gem install notion_to_html
```
## Dependencies
NotionToHtml uses [tailwindcss](https://tailwindcss.com/) classes to define a default styling that mimics Notion's own styling, so make sure to inlcude it in your application.
If you wish to use something else you can always override the default styling provided, see [Customizing styles](#customizing-styles) for more details.

## Setup
This gem is currently very opinionated on how it expects the Notion database to be defined. If you wish to customize this you can override the methods defined in [NotionToHtml::Service](./lib/notion_to_html/service.rb).

By default the database should have the following structure:
![Database structure](/docs/images/database_structure.png)

- _name, description & slug_ as Text
- tags as Multi-Select
- public as Checkbox
- published as Date

Once you have the database created you will have to setup a Notion Integration, so the Notion API can communicate with your database. For this you will have to follow the [Create Your Integration In Notion](https://developers.notion.com/docs/create-a-notion-integration#create-your-integration-in-notion) tutorial.

If you wish to just quickly set it up, you can follow the [notion integration docs](/docs/notion_setup.md), which are taken from that tutorial.

## Configuration
To configure NotionToHtml, you need to set up your Notion API token and database ID.
If you're using Rails add an initializer file in your Rails application, such as `config/initializers/notion_to_html.rb`, and include the following configuration block:
```ruby
NotionToHtml.configure do |config|
  config.notion_api_token = 'NOTION_API_TOKEN'
  config.notion_database_id = 'NOTION_DATABASE_ID'
  config.cache_store = Rails.cache
end
```

To get these values:
1. The NOTION_API_TOKEN is the same one from [the setup](#get-your-api-secret).
2. To get the NOTION_DATABASE_ID, locate the 32-character string at the end of the page’s URL.
    ```bash
    https://www.notion.so/myworkspace/a8aec43384f447ed84390e8e42c2e089?v=...
                                      |--------- Database ID --------|
    ```

**Remember to keep these values secret!**

Now you should be all setup!

For the full list of configuration settings, see [the configuration module](./lib/notion_to_html.rb).

## Usage
### Rendering
#### Pages
To get and render a preview of the pages of your database:
```ruby
<% NotionToHtml::Service.get_pages.each do |page| %>
  <%= article.formatted_published_at %>
  <%= article.id %>
  <%= article.formatted_title %>
  <%= article.formatted_description %>
<% end %>
```
#### Specific Page
To get and render a specific page:
```ruby
<% page = NotionToHtml::Service.get_page(page_id) %>
<%= page.formatted_title %>
<%= page.formatted_published_at %>
<% page.formatted_blocks.each do |block| %>
  <%= block %>
<% end %>
```
#### Customizing styles
NotionToHtml ships with default css classes for each supported block. You can add your own set of styling on top by specifying the `class:` option when calling the formatter:
```ruby
NotionToHtml::Service.get_page(page_id)
  .formatted_title(class: 'text-4xl md:text-5xl font-bold')
```
You can also specify classes for each type of supported block like this:
```ruby
NotionToHtml::Service.get_page(page_id).formatted_blocks(
  paragraph: { class: 'text-lg' }, 
  heading_1: { class: 'text-3xl md:text-4xl font-bold' }, 
  heading_2: { class: 'text-white' }, 
  heading_3: { class: 'font-bold' }, 
  quote: { class: 'italic' }, 
)
```
#### Overriding default styles
If you feel like you want a clean slate regarding styling you can override the provided default styles by setting the `override_class` option to `true`:
```ruby
NotionToHtml::Service.get_page(page_id)
  .formatted_title(class: 'font-bold', override_class: true)
```
It also works for `formatted_blocks`:
```ruby
NotionToHtml::Service.get_page(page_id)
  .formatted_blocks(
    paragraph: { class: 'text-lg', override_class: true }, 
    quote: { class: 'italic' } 
)
```
#### Adding data options
If you want to integrate stimulus you can add data properties by specifying the `data:` option when calling the formatter:
```ruby
NotionToHtml::Service.get_page(page_id).formatted_blocks(
  paragraph: { class: 'text-lg', data: { controller: 'test' } } }, 
  heading_1: { class: 'text-3xl md:text-4xl font-bold' }, 
  heading_2: { class: 'text-white', data: { controller: 'click' } }, 
  heading_3: { class: 'font-bold' }, 
  quote: { class: 'italic' }, 
)
```
### Querying
By default the `NotionToHtml::Service` is setup to follow the database structure sepcified above. This way it will only return pages that have been marked as `public`.

#### Filtering
You can filter the results by specifying a name, description, tag and/or a specific slug:
```ruby
NotionToHtml::Service.get_pages(name: 'Ruby', description: 'ruby on rails', tag: 'web', slug: 'test-slug')
```
This will return all the pages that have at least one of those specified attributes.
#### Sorting
The default sorting is by the `published` Date column in the database

### Examples
To see how the default renderings of the supported blocks look, go over to the [examples](/examples/).

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on [Github](https://github.com/guillermoap/notion_to_html). This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Notion::Rails project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](/CODE_OF_CONDUCT.md).
