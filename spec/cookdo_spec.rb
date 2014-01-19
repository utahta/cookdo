# coding: utf-8
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require "rspec"
require "cooklib"

describe Cook do
  before {
    @cook = Cook.new(:category=>"177")
  }
  
  it "レシピの最大数は0以上" do
    expect(@cook.get_recipe_maxnum).to be > 0
  end
  
  it "レシピを取得" do
    recipe = @cook.get_recipe(1)
    expect(recipe.length).to be > 0
  end
end
