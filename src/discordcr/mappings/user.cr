require "./converters"

module Discord
  struct User
    include JSON::Serializable

    # :nodoc:
    def initialize(partial : PartialUser)
      @username = partial.username.not_nil!
      @id = partial.id
      @discriminator = partial.discriminator.not_nil!
      @avatar = partial.avatar
      @email = partial.email
      @bot = partial.bot
    end

    property username : String
    property id : Snowflake
    property discriminator : String
    property avatar : String?
    property email : String?
    property bot : Bool?
    property system : Bool?
    property mfa_enabled : Bool?
    property verified : Bool?
    property member : PartialGuildMember?
    property flags : UserFlags?

    # Produces a CDN URL to this user's avatar in the given `size`.
    # If the user has an avatar a WebP will be returned, or a GIF
    # if the avatar is animated. If the user has no avatar, a default
    # avatar URL is returned.
    def avatar_url(size : Int32 = 128)
      if avatar = @avatar
        CDN.user_avatar(id, avatar, size)
      else
        CDN.default_user_avatar(discriminator)
      end
    end

    # Produces a CDN URL to this user's avatar, in the given `format` and
    # `size`. If the user has no avatar, a default avatar URL is returned.
    def avatar_url(format : CDN::UserAvatarFormat, size : Int32 = 128)
      if avatar = @avatar
        CDN.user_avatar(id, avatar, format, size)
      else
        CDN.default_user_avatar(discriminator)
      end
    end

    # Produces a string to mention this user in a message
    def mention
      "<@#{id}>"
    end
  end

  @[Flags]
  enum UserFlags : UInt16
    DiscordEmployee = 1 << 0
    DiscordPartner  = 1 << 1
    HypeSquadEvents = 1 << 2
    BugHunter       = 1 << 3
    HouseBravery    = 1 << 6
    HouseBrilliance = 1 << 7
    HouseBalance    = 1 << 8
    EarlySupporter  = 1 << 9
    TeamUser        = 1 << 10
    System          = 1 << 12

    def self.new(pull : JSON::PullParser)
      UserFlags.new(pull.read_int.to_u16)
    end
  end

  struct PartialUser
    include JSON::Serializable

    property username : String?
    property id : Snowflake
    property discriminator : String?
    property avatar : String?
    property email : String?
    property bot : Bool?

    def full? : Bool
      !@username.nil? && !@discriminator.nil? && !@avatar.nil?
    end
  end

  struct UserGuild
    include JSON::Serializable

    property id : Snowflake
    property name : String
    property icon : String?
    property owner : Bool
    property permissions : Permissions
  end

  struct Connection
    include JSON::Serializable

    property id : Snowflake
    property name : String
    property type : String
    property revoked : Bool
  end
end
