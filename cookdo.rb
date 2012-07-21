# coding: utf-8
require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'csv'
require 'json'
require 'optparse'

class Recipe
  attr_accessor :title, :url, :count
  
  def initialize(title, url)
    @title = title
    @url = url
    @count = 0
  end

  def get_hatebu()
    4.times do
      begin
        html = open("http://b.hatena.ne.jp/entry/jsonlite/?url=#{@url}").read
      rescue
        puts "はてぶ取得エラー...10秒待機 #{@url}"
        sleep(10)
        next
      end
      
      begin
        if html != 'null'
          obj = JSON.parse(html)
          @count = obj["count"].to_i
        end
      rescue
        puts "JSONパースエラー...1秒待機 #{@url} #{html}"
        sleep(1)
        next
      end
      break
    end
  end
  
  def csv()
    [@title, @url, @count]
  end
  
end

class Cook
  def initialize()
    @opts = {}
    op = OptionParser.new do |opt|
      opt.on('-c ID', '--category=ID', 'カテゴリーを指定(177, 19とか)') {|v| @opts[:category] = v}
      opt.on('-r NAME', '--recipe=NAME', 'レシピ名を指定(牛肉とか)') {|v| @opts[:recipe] = v}
      opt.on('-f FILE', '--file=FILE', 'レシピファイル') {|v| @opts[:file] = v}
      
      opt.parse!
    end
    if @opts.empty? or (@opts[:category].nil? and @opts[:recipe].nil? and @opts[:file].nil?)
      puts op
      exit
    end
  end
  
  def get_recipe_url(page=1)
    if @opts[:category]
      "http://cookpad.com/category/#{@opts[:category]}?page=#{page}"
    elsif @opts[:recipe]
      URI.escape("http://cookpad.com/レシピ/#{@opts[:recipe]}?order=date&page=#{page}")
    end
  end
  
  def get_recipe_maxnum()
    site_url = get_recipe_url()
    html = open(site_url).read
    doc = Nokogiri::HTML(html)
    if @opts[:category]
      page = doc.xpath('//span[@class="page_num"]')[0].text.strip
      page[/ ([0-9,]+)/].strip.gsub(",", "").to_i
    elsif @opts[:recipe]
      page = doc.xpath('//span[@class="page_top"]')[0].text.strip
      page = page[/\/([0-9,]+)/].strip
      page[1..page.length].gsub(",", "").to_i
    end
  end
  
  def get_recipe(page)
    html = nil
    3.times do
      begin
        site_url = get_recipe_url(page)
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
  
  def get_recipes(max_num)
    puts "解析開始"
    recipes = []
    for page in 1..max_num
      puts "#{page} ページ目を解析中..."
      recipes += get_recipe(page)
      sleep(0.3)
    end
    puts "解析完了"
    recipes
  end
  
  def save_recipes(recipes, path)
    puts "ファイル書き出し開始"
    CSV.open(path, 'w') do |io|
      recipes.each do |recipe|
        io << recipe.csv
      end
    end
    puts "書き出し完了"
  end
  
  def load_recipes(file)
    puts "ファイル読み込み開始..."
    recipes = []
    CSV.foreach(file) do |row|
      recipes.push(Recipe.new(row[0], row[1]))
    end
    puts "読み込み完了"
    recipes
  end
  
  def get_recipes_hatebu(tmp)
    puts "はてブ取得開始"
    num = 1
    recipes = []
    tmp.each do |recipe|
      recipe.get_hatebu
      if recipe.count > 10
        recipes.push(recipe)
      end
      puts "#{recipe.title} #{recipe.url} #{recipe.count} #{num}"
      num += 1
    end
    puts "はてブ取得完了"
    recipes
  end
  
  def do()
    now = Time.now.to_i

    if @opts[:file]
      recipes = load_recipes(@opts[:file])
    else
      # Cookpad
      max_num = get_recipe_maxnum()
      recipes = get_recipes(max_num)
      save_recipes(recipes, "cookdo_#{now}.csv")
    end
        
    # Hatebu
    recipes = get_recipes_hatebu(recipes)
    save_recipes(recipes, "hatebudo_#{now}.csv")
  end
  
end

# main
cook = Cook.new
cook.do
