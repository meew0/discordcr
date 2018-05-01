# This simple example bot creates a message whenever a new user joins the server.

require "../src/discordcr"

# Make sure to replace this fake data with actual data when running.
client = Discord::Client.new(token: "Bot MjI5NDU5NjgxOTU1NjUyMzM3.Cpnz31.GQ7K9xwZtvC40y8MPY3eTqjEIXm", client_id: 229459681955652337_u64)
cache = Discord::Cache.new(client)

welcome_channel = nil

client.on_message_create do |payload|
  # Here we take for example "#welcome", "#general" or some other channel as the argument and then we put the ID of it into welcome_channel.
  if match = payload.content.match(/\!setwelcome <#(?<id>\d+)>/)
    welcome_channel = match["id"].to_u64
    client.create_message(payload.channel_id, "Successfully set a welcome channel.")
  elsif payload.content.starts_with?("!setwelcome")
    client.create_message(payload.channel_id, "Please specify a valid welcome channel.")
  end
end

client.on_guild_member_add do |payload|
  if id = welcome_channel
    # Get the guild/server information.
    guild = cache.resolve_guild(payload.guild_id)

    client.create_message(id, "Please welcome <@#{payload.user.id}> to #{guild.name}.")
  end
end

client.run
