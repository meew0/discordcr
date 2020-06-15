require "./converters"
require "./user"

module Discord
  # An OAuth2 application, as registered with Discord, that can hold
  # information about a `Client`'s associated bot user account and owner,
  # among other OAuth2 properties.
  struct OAuth2Application
    include JSON::Serializable

    property id : Snowflake
    property name : String
    property icon : String?
    property description : String?
    property rpc_origins : Array(String)?
    property bot_public : Bool
    property bot_require_code_grant : Bool
    property owner : User
    property summary : String
    property verify_key : String
    property team : Team?
    property guild_id : Snowflake?
    property primary_sku_id : String?
    property slug : String?
    property cover_image : String?

    # Produces a CDN URL for this application's icon in the given `format` and `size`
    def icon_url(format : CDN::ApplicationIconFormat = CDN::ApplicationIconFormat::WebP,
                 size : Int32 = 128)
      if icon = @icon
        CDN.application_icon(id, icon, format, size)
      end
    end
  end

  struct Team
    include JSON::Serializable

    property icon : String?
    property id : Snowflake
    property members : Array(TeamMember)
    property owner_user_id : Snowflake
  end

  struct TeamMember
    include JSON::Serializable

    property membership_state : TeamMembershipState
    property permissions : Array(String)
    property team_id : Snowflake
    property user : User
  end

  enum TeamMembershipState : UInt8
    Invited  = 1
    Accepted = 2

    def self.new(pull : JSON::PullParser)
      TeamMembershipState.new(pull.read_int.to_u8)
    end
  end
end
