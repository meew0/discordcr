require "./spec_helper"
require "./mock_server"

describe Discord::REST do
  client = Discord::Client.new(token: "Bot token")

  describe "#encode_tuple" do
    it "doesn't emit null values" do
      client = Discord::Client.new("foo", 0_u64)
      client.encode_tuple(foo: ["bar", 1, 2], baz: nil).should eq(%({"foo":["bar",1,2]}))
    end
  end

  {% if flag?(:mock_server) %}
    it "#create_message" do
      expected = Discord::Message.from_json <<-JSON
      {
        "id": "2",
        "channel_id": "1",
        "author": {
          "id": "120571255635181568",
          "username": "z64",
          "discriminator": "1337",
          "avatar": "a_d91d42bc7c02bfbfa195c8f66e4a9d47"
        },
        "content": "foo",
        "timestamp": "2018-08-06T19:28:05.00+0000",
        "edited_timestamp": null,
        "tts": false,
        "mention_everyone": false,
        "mentions": [],
        "mention_roles": [],
        "attachments": [],
        "embeds": [],
        "reactions": [],
        "nonce": null,
        "pinned": false,
        "webhook_id": null,
        "type": 0,
        "activity": null,
        "application": null
      }
      JSON
      Discord::MockServer.prepare_endpoint("POST", "/channels/1/messages", 200,
        {"Content-Type" => "application/json"}, expected.to_json)
      client.create_message(1, "foo").should eq expected
    end

    it "#delete_message" do
      Discord::MockServer.prepare_endpoint("DELETE", "/channels/1/messages/2", 204,
        {"Content-Type" => "application/json"}, "")
      client.delete_message(1, 2)
    end
  {% end %}
end
