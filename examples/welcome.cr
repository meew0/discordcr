# This simple example bot creates a message whenever a new user joins the server.

require "../src/discordcr"

# Make sure to replace this fake data with actual data when running.
client = Discord::Client.new(token: "Bot MjI5NDU5NjgxOTU1NjUyMzM3.Cpnz31.GQ7K9xwZtvC40y8MPY3eTqjEIXm", client_id: 229459681955652337_u64)
cache = Discord::Cache.new(client)
client.cache = cache

welcome_channel = 0_u64

client.on_message_create do |payload|
  # Here we take for example "#welcome", "#general" or some other channel as the argument and then we put the ID of it into welcome_channel.
  if payload.content.starts_with? "!setwelcome"
    welcome_channel = payload.content.split(" ")[1][2..-2].to_u64
  end
end

client.on_guild_member_add do |payload|
  # Break up if the welcome_channel isn't set yet.
  if welcome_channel==0
    next
  end

  # Get the guild/server information.
  guild = cache.resolve_guild(payload.guild_id)

  client.create_message(welcome_channel, "Please welcome <@#{payload.user.id}> to #{guild.name}.")
end

client.run
