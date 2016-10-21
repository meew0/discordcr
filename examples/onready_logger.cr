# This simple example bot logs the number of connected Guilds & Private Channels.
#
# Also uses the logger with a passed progname.

require "../src/discordcr"

# Make sure to replace this fake data with actual data when running.
client = Discord::Client.new(token: "Bot MjI5NDU5NjgxOTU1NjUyMzM3.Cpnz31.GQ7K9xwZtvC40y8MPY3eTqjEIXm", client_id: 229459681955652337_u64)

client.on_ready do |payload|
  Discord::LOGGER.info "Connected Guilds: #{payload.guilds.size}"
  Discord::LOGGER.info("Connected Private Channels: #{payload.private_channels.size}", "MyBot")
end

client.run
