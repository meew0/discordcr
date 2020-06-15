require "./converters"
require "./user"

module Discord
  struct Invite
    include JSON::Serializable

    property code : String
    property guild : InviteGuild
    property channel : InviteChannel
  end

  struct InviteMetadata
    include JSON::Serializable

    property code : String
    property guild : InviteGuild
    property channel : InviteChannel
    property inviter : User
    property users : UInt32
    property max_uses : UInt32
    property max_age : UInt32
    property temporary : Bool
    @[JSON::Field(converter: TimestampConverter)]
    property created_at : Time
    property revoked : Bool
  end

  struct InviteGuild
    include JSON::Serializable

    property id : Snowflake
    property name : String
    property splash_hash : String?
  end

  struct InviteChannel
    include JSON::Serializable

    property id : Snowflake
    property name : String
    property type : UInt8
  end
end
