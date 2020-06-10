require "./converters"
require "./user"

module Discord
  struct Webhook
    include JSON::Serializable
    property id : Snowflake
    property guild_id : Snowflake?
    property channel_id : Snowflake
    property user : User?
    property name : String
    property avatar : String?
    property token : String
  end
end
