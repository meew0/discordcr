require "./converters"

module Discord
  struct VoiceState
    include JSON::Serializable
    property guild_id : Snowflake?
    property channel_id : Snowflake?
    property user_id : Snowflake
    property member : GuildMember?
    property session_id : String
    property deaf : Bool
    property mute : Bool
    property self_deaf : Bool
    property self_mute : Bool
    property suppress : Bool
  end

  struct VoiceRegion
    include JSON::Serializable
    property id : String
    property name : String
    property sample_hostname : String
    property sample_port : UInt16
    property custom : Bool?
    property vip : Bool
    property optimal : Bool
  end
end
