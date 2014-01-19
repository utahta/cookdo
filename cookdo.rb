# coding: utf-8
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rubygems'
require 'optparse'
require 'cooklib'

opts = {}
op = OptionParser.new do |opt|
  opt.on('-c ID', '--category=ID', 'カテゴリーを指定(177, 19とか)') {|v| opts[:category] = v}
  opt.on('-r NAME', '--recipe=NAME', 'レシピ名を指定(牛肉とか)') {|v| opts[:recipe] = v}
  opt.on('-f FILE', '--file=FILE', 'レシピファイル') {|v| opts[:file] = v}
  
  opt.parse!
end
if opts.empty? or (opts[:category].nil? and opts[:recipe].nil? and opts[:file].nil?)
  puts op
  exit
end

cook = Cook.new(opts)
cook.do