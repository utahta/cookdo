# coding: utf-8
require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'csv'
require 'optparse'

class Recipe
  attr_accessor :title, :url
  
  def initialize(title, url)
    @title = title
    @url = url
  end
  
  def csv()
    [@title, @url]
  end
  
end

def get_cookpad_recipe_maxnum(category)
  site_url = "http://cookpad.com/category/#{category}"
  html = open(site_url).read
  doc = Nokogiri::HTML(html)
  page = doc.xpath('//span[@class="page_num"]')[0].text.strip
  page[/ ([0-9,]+)/].strip.gsub(",", "").to_i
end

def get_cookpad_recipe(category, page)
  html = nil
  3.times do
    begin
      site_url = "http://cookpad.com/category/#{category}?page=#{page}"
      html = open(site_url).read
    rescue
      puts "レシピ取得エラー 10秒待機"
      sleep(10)
      next
    end
    break
  end
  doc = Nokogiri::HTML(html)
  rows = doc.xpath('//div[@class="recipe-preview"]')
  
  recipes = []
  rows.each do |row|
    a = row.xpath('.//a[@class="recipe-title font13"]')[0]
    title = a.text.strip
    url = a[:href]
    
    recipes.push(Recipe.new(title, url))
  end
  recipes
end

# main
opts = {}
op = OptionParser.new do |opt|
  opt.on('-c ID', '--category=ID', 'カテゴリーを指定(177, 19)') {|v| opts[:category] = v}

  opt.parse!
end
if opts.empty? or opts[:category].nil?
  puts op
  exit
end
category = opts[:category]

max_num = get_cookpad_recipe_maxnum(category)

puts "解析開始"
recipes = []
for page in 1..max_num
  puts "#{page} ページ目を解析中..."
  recipes += get_cookpad_recipe(category, page)
  sleep(0.3)
end
puts "解析完了"

puts "ファイル書き出し開始"
CSV.open('cookdo.csv', 'w') do |io|
  recipes.each do |recipe|
    io << recipe.csv
  end
end
puts "書き出し完了"
