#!/usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'json'

page = Nokogiri::HTML(open('http://www.alec.org/model-legislation/'))
FILENAME = ARGV.first || "alec-model-bills.json"
bill_urls = []
bills = []

# helper functions

def get_bill_info(url)

  bill_page = Nokogiri::HTML(open(url))
  bill_title = bill_page.css('#title').text

  puts "#{bill_title}: #{url}"

  # this removes the bill title and tags from the content
  content_paragraphs = bill_page.css('#main p')
  text = content_paragraphs[1..content_paragraphs.length - 2].map(&:text).join(' ')

  # extract the bill tags
  tags = []
  tags_paragraph = bill_page.css('#content p').select{ |p| p.text.downcase.include?('keyword tags') }
  tags = tags_paragraph[0].text.gsub!('Keyword Tags:', '').split(',').map(&:strip) if tags_paragraph.count > 0

  bill = {
      title: bill_title,
      source_url: url,
      content: bill_page.css('#main')[0].text,
      text: text,
      html: bill_page.css('#main')[0].inner_html,
      tags: tags
  }
end

def save_results(results)
  File.open(FILENAME, "w") do |f|
    f.write(results.to_json)
  end
end

# process

page.css('#features .model-legislation').each do |bill|
  title = bill.css('h3').text.strip
  url = bill.css('a')[0]['href']
  bill_urls << url
end

bill_urls.each do |url|
  bills << get_bill_info(url)
  save_results(bills)
end
