require "./spec_helper"

class Storage
  getter value

  def initialize(@value : Int32)
  end
end

describe Discord::Context do
  it "stores and recalls values by type" do
    context = Discord::Context.new
    context.put Storage.new(1)
    context[Storage].value.should eq 1
  end

  it "raises on a type that hasn't been stored" do
    context = Discord::Context.new
    expect_raises(KeyError, "Missing reference in context to Storage") do
      context[Storage]
    end
  end
end
