# coding: utf-8
require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'csv'

class Hatebu
  attr_accessor :title, :url, :count
  
  def initialize(title, url)
    @title = title
    @url = url
    @count = 0
    get_hatebu
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
        puts "JSONパースエラー...10秒待機 #{@url} #{html}"
      end
      break
    end
  end
  
  def csv()
    [@title, @url, @count]
  end
  
end

hatebus = []

puts "ファイル読み込み開始..."
count = 1
CSV.foreach('cookdo.csv') do |row|
  hatebu = Hatebu.new(row[0], row[1])
  if hatebu.count > 50
    hatebus.push(hatebu)
  end
  puts "#{hatebu.title} #{hatebu.url} #{hatebu.count} #{count}"
  count += 1
end
puts "読み込み完了"

puts "ソート開始"
hatebus.sort!{|a, b|
  a.count <=> b.count
}.reverse!
puts "ソート完了"

puts "ファイル書き出し開始"
CSV.open('hatebudo.csv', 'w') do |io|
  hatebus.each do |hatebu|
    io << hatebu.csv
  end
end
puts "書き出し完了"
