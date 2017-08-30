require "./converters"

module Discord
  module REST
    # A response to the Get Gateway REST API call.
    struct GatewayResponse
      JSON.mapping(
        url: String
      )
    end

    # A response to the Get Guild Prune Count REST API call.
    struct PruneCountResponse
      JSON.mapping(
        pruned: UInt32
      )
    end

    # A payload for the Modify Channel REST API call.
    #
    # Used instead of a tuple to control null emitting.
    struct ModifyChannelPayload
      JSON.mapping(
        name: String?,
        position: UInt32?,
        topic: String?,
        bitrate: UInt32?,
        user_limit: UInt32?,
        nsfw: Bool?
      )

      def initialize(@name, @position, @topic, @bitrate, @user_limit, @nsfw)
      end
    end

    # A payload for the Modify Guild REST API call.
    #
    # Used instead of a tuple to control null emitting.
    struct ModifyGuildPayload
      JSON.mapping(
        name: String?,
        region: String?,
        verification_level: UInt8?,
        afk_channel_id: UInt64?,
        afk_timeout: Int32?,
        icon: String?,
        owner_id: UInt64?,
        splash: String?
      )

      def initialize(@name, @region, @verification_level, @afk_channel_id,
                     @afk_timeout, @icon, @owner_id, @splash)
      end
    end

    # A payload for the Modify Guild Member REST API call.
    #
    # Used instead of a tuple to control null emitting.
    struct ModifyGuildMemberPayload
      JSON.mapping(
        nick: String?,
        roles: Array(UInt64)?,
        mute: Bool?,
        deaf: Bool?,
        channel_id: UInt64?
      )

      def initialize(@nick, @roles, @mute, @deaf, @channel_id)
      end
    end

    # A payload for the Modify Guild Role REST API call.
    #
    # Used instead of a tuple to control null emitting.
    struct ModifyGuildRolePayload
      JSON.mapping(
        name: String?,
        permissions: Permissions?,
        colour: UInt32?,
        position: Int32?,
        hoist: Bool?
      )

      def initialize(@name, @permissions, @colour, @position, @hoist)
      end
    end

    # A payload for the Modify Current User REST API call.
    #
    # Used instead of a tuple to control null emitting.
    struct ModifyCurrentUserPayload
      JSON.mapping(
        username: String?,
        avatar: String?
      )

      def initialize(@username, @avatar)
      end
    end
  end
end
