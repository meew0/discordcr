require "./client"

module Discord
  # `CachedClient` is an extension of `Client` that adds customizable caches to track state.
  class CachedClient < Client
    getter! cache_set : Cache::CacheSet

    def initialize(token : String, client_id : UInt64,
                   shard : Gateway::ShardKey? = nil,
                   large_threshold : Int32 = 100,
                   compress : Bool = false,
                   properties : Gateway::IdentifyProperties = DEFAULT_PROPERTIES)
      super(token, client_id, shard, large_threshold, compress, properties)
      @cache_set = Cache::CacheSet.new(self)
    end

    macro cached_route(method, key_type, resource_type)
      {% if key_type.is_a?(TupleLiteral) %}
        {{index = 0}}
        {{typed_args = key_type.map { |key| index = index + 1; "arg#{index} : #{key}" }}}

        {{index = 0}}
        {{args = key_type.map { |key| index = index + 1; "arg#{index}" }}}
        # See `REST#{{method}}`
        def {{method}}({{typed_args.map(&.id).splat}})
          if cache = cache_set[{{resource_type}}]
            object = cache.resolve?({{args.map(&.id)}})
            object ||= cache.cache(
              {{args.map(&.id)}},
              super({{args.map(&.id).splat}})
            )
          else
            super({{args.map(&.id).splat}})
          end
        end
      {% else %}
        # See `REST#{{method}}`
        def {{method}}(id : {{key_type}})
          if cache = cache_set[{{resource_type}}]
            object = cache.resolve?(id)
            object ||= cache.cache super(id)
          else
            super(id)
          end
        end
      {% end %}
    end

    cached_route get_guild, UInt64, Guild

    cached_route get_guild_member, {UInt64, UInt64}, GuildMember

    cached_route get_guild_channel, UInt64, Channel

    # See `REST#get_guild_roles`
    def get_guild_roles(id : UInt64)
      if cache = cache_set.role
        roles = cache.resolve(id)
        return roles unless roles.empty?
        new_roles = super(id)
        new_roles.map { |role| cache.cache({id, role.id}, role) }
      else
        super(id)
      end
    end
  end
end
