require "./converters"

module Discord
  module REST
    # A response to the Get Gateway REST API call.
    struct GatewayResponse
      include JSON::Serializable

      property url : String
    end

    # A response to the Get Gateway Bot REST API call.
    struct GatewayBotResponse
      include JSON::Serializable

      property url : String
      property shards : Int32
      property session_start_limit : SessionStartLimit
    end

    # Session start limit details included in the Get Gateway Bot REST API call.
    struct SessionStartLimit
      include JSON::Serializable

      property total : Int32
      property remaining : Int32
      @[JSON::Field(converter: TimeSpanMillisecondsConverter)]
      property reset_after : Time::Span
    end

    # A response to the Get Guild Prune Count REST API call.
    struct PruneCountResponse
      include JSON::Serializable

      property pruned : UInt32
    end

    # A response to the Get Guild Vanity URL REST API call.
    struct GuildVanityURLResponse
      include JSON::Serializable

      property code : String
    end

    # A request payload to rearrange channels in a `Guild` by a REST API call.
    struct ModifyChannelPositionPayload
      @id : Snowflake

      def initialize(id : UInt64 | Snowflake, @position : Int32,
                     @parent_id : UInt64 | Snowflake | ChannelParent = ChannelParent::Unchanged,
                     @lock_permissions : Bool? = nil)
        id = Snowflake.new(id) unless id.is_a?(Snowflake)
        @id = id
      end

      def to_json(builder : JSON::Builder)
        builder.object do
          builder.field("id") { @id.to_json(builder) }

          builder.field("position", @position)

          case parent = @parent_id
          when UInt64, Snowflake
            parent.to_json(builder)
          when ChannelParent::None
            builder.field("parent_id", nil)
          when ChannelParent::Unchanged
            # no field
          end

          builder.field("lock_permissions", @lock_permissions) unless @lock_permissions.nil?
        end
      end
    end

    # A request payload to rearrange roles in a `Guild` by a REST API call.
    struct ModifyRolePositionPayload
      include JSON::Serializable

      property id : Snowflake
      property position : Int32

      def initialize(id : UInt64 | Snowflake, @position : Int32)
        id = Snowflake.new(id) unless id.is_a?(Snowflake)
        @id = id
      end
    end
  end
end
