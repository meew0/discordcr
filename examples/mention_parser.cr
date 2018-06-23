# This example demonstrates usage of `Discord::Mention.parse` to parse
# and handle different kinds of mentions appearing in a message.

require "../src/discordcr"

# Make sure to replace this fake data with actual data when running.
client = Discord::Client.new(token: "Bot MjI5NDU5NjgxOTU1NjUyMzM3.Cpnz31.GQ7K9xwZtvC40y8MPY3eTqjEIXm")

client.on_message_create do |payload|
  next unless payload.content.starts_with?("parse:")

  mentions = String.build do |io|
    index = 0
    Discord::Mention.parse(payload.content) do |mention|
      index += 1
      io << "`[" << index << " @ " << mention.start << "]` "
      case mention
      when Discord::Mention::User
        io.puts "**User:** #{mention.id}"
      when Discord::Mention::Role
        io.puts "**Role:** #{mention.id}"
      when Discord::Mention::Channel
        io.puts "**Channel:** #{mention.id}"
      when Discord::Mention::Emoji
        io << "**Emoji:** #{mention.name} #{mention.id}"
        io << " (animated)" if mention.animated
        io.puts
      when Discord::Mention::Everyone
        io.puts "**Everyone**"
      when Discord::Mention::Here
        io.puts "**Here**"
      end
    end
  end

  mentions = "No mentions found in your message" if mentions.empty?

  begin
    client.create_message(
      payload.channel_id.value,
      mentions)
  rescue ex
    client.create_message(
      payload.channel_id.value,
      "`#{ex.inspect}`")
    raise ex
  end
end

client.run
