require "./spec_helper"

alias TestCache = Discord::MemoryCache(Int32, String)

describe Discord::MemoryCache do
  it "caches and recalls values" do
    instance = TestCache.new
    instance.resolve?(1).should eq nil
    instance.cache(1, "foo")
    instance.resolve?(1).should eq "foo"
  end

  it "#remove" do
    instance = TestCache.new
    instance.cache(1, "foo")
    instance.resolve(1).should eq "foo"
    instance.remove(1)
    instance.resolve?(1).should eq nil
  end

  describe "#resolve" do
    it "raises for missing members" do
      instance = TestCache.new
      expect_raises(Discord::Cache::Error, "Cache member not found: 1") do
        instance.resolve(1)
      end
    end
  end

  describe "#fetch" do
    it "returns an existing member" do
      instance = TestCache.new
      instance.cache(1, "foo")
      instance.fetch(1) { "bar" }.should eq "foo"
    end

    it "caches the block on a missing member" do
      instance = TestCache.new
      instance.fetch(2) { "bar" }.should eq "bar"
    end
  end
end
