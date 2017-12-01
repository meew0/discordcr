require "./spec_helper"

def it_converts(json, to value, with converter, file = __FILE__, line = __LINE__)
  describe converter, file, line do
    it "converts #{json} to #{value.class}" do
      parser = JSON::PullParser.new(json)
      converted = converter.from_json(parser)
      converted.should eq value
    end

    it "serializes #{value} to JSON" do
      converted = JSON.build do |builder|
        converter.to_json(value, builder)
      end

      converted.should eq json
    end
  end
end

describe "Converters" do
  it_converts(%("10000000000"), to: 10000000000_u64, with: Discord::SnowflakeConverter)
  it_converts(%("10000000000"), to: 10000000000_u64, with: Discord::MaybeSnowflakeConverter)
  it_converts("null", to: nil, with: Discord::MaybeSnowflakeConverter)
  it_converts(%(["1","2","10000000000"]), to: [1_u64, 2_u64, 10000000000_u64], with: Discord::SnowflakeArrayConverter)

  pending "Discord::EmbedTimestampConverter" do
  end
end
