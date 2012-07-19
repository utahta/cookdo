# coding: utf-8
require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'csv'

class Recipe
  attr_accessor :title, :url, :hatebu
  
  def initialize(title, url)
    @title = title
    @url = url
    @hatebu = 0
    get_hatebu
  end
  
  def get_hatebu()
    html = open("http://b.hatena.ne.jp/entry/jsonlite/?url=#{@url}").read
    if html != 'null'
      obj = JSON.parse(html)
      @hatebu = obj["count"].to_i
    end
  end
  
  def csv()
    [@title, @url, @hatebu]
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
  site_url = "http://cookpad.com/category/#{category}?page=#{page}"
  html = open(site_url).read
  doc = Nokogiri::HTML(html)
  rows = doc.xpath('//div[@class="recipe-preview"]')
  
  recipes = []
  rows.each do |row|
    a = row.xpath('.//a[@class="recipe-title font13"]')[0]
    title = a.text.strip
    
    a = row.xpath('.//div[@class="recipe-image wide"]/a')[0]
    url = a[:href]
    
    recipes.push(Recipe.new(title, url))
  end
  recipes
end

CAT_MENU = 177

max_num = get_cookpad_recipe_maxnum(CAT_MENU)
max_num = 1

recipes = []
for page in 1..max_num
  recipes += get_cookpad_recipe(CAT_MENU, page)
  sleep(0.3)
end

recipes.sort!{|a, b|
  a.hatebu <=> b.hatebu
}.reverse!

CSV.open('sort.csv', 'w') do |io|
  recipes.each do |recipe|
    io << recipe.csv
  end
end
