require "./client"
require "./cache"

module Discord
  class CachedClient < Client
    property user_cache : Cache(UInt64, User) = NullCache(UInt64, User).new

    property guild_cache : Cache(UInt64, Guild) = NullCache(UInt64, Guild).new

    property guild_member_cache : Cache(Tuple(UInt64, UInt64), GuildMember) = NullCache(Tuple(UInt64, UInt64), GuildMember).new

    property channel_cache : Cache(UInt64, Channel) = NullCache(UInt64, Channel).new

    property role_cache : Cache(UInt64, Role) = NullCache(UInt64, Role).new

    property dm_channel_cache : Cache(UInt64, UInt64) = NullCache(UInt64, UInt64).new

    property guild_role_cache : Cache(UInt64, Array(UInt64)) = NullCache(UInt64, Array(UInt64)).new

    property guild_channel_cache : Cache(UInt64, Array(UInt64)) = NullCache(UInt64, Array(UInt64)).new

    def initialize(@token : String, @client_id : UInt64? = nil,
                   @shard : Gateway::ShardKey? = nil,
                   @large_threshold : Int32 = 100,
                   @compress : Bool = false,
                   @properties : Gateway::IdentifyProperties = DEFAULT_PROPERTIES)
      super
      initialize_handlers
    end

    def get_user(id : UInt64, cached : Bool = true)
      if cached
        user_cache.fetch(id) { super(id) }
      else
        user = super(id)
        user_cache.cache(user.id, user)
      end
    end

    def get_guild(id : UInt64, cached : Bool = true)
      if cached
        guild_cache.fetch(id) { super(id) }
      else
        guild = super(id)
        guild_cache.cache(guild.id, guild)
      end
    end

    def get_guild_member(guild_id : UInt64, user_id : UInt64, cached : Bool = true)
      if cached
        guild_member_cache.fetch({guild_id, user_id}) do
          super(guild_id, user_id)
        end
      else
        member = super(guild_id, user_id)
        guild_member_cache.cache({guild_id, user_id}, member)
      end
    end

    def get_channel(id : UInt64, cached : Bool = true)
      if cached
        channel_cache.fetch(id) { super(id) }
      else
        channel = super(id)
        channel_cache.cache(channel.id, channel)
      end
    end

    private def initialize_handlers
      on_ready do |payload|
        # TODO: Current user cache?
        payload.private_channels.each do |channel|
          channel_cache.cache(channel.id, Channel.new(channel))
          if channel.type.dm?
            dm_channel_cache.cache(channel.id, channel.recipients[0].id)
          end
        end
      end

      on_guild_create do |payload|
        guild = Guild.new(payload)
        guild_cache.cache(guild.id, guild)

        payload.channels.each do |channel|
          channel.guild_id = payload.id
          channel_cache.cache(channel.id, channel)
          guild_channel_cache.fetch(payload.id) { Array(UInt64).new }.push(channel.id)
        end

        payload.roles.each do |role|
          role_cache.cache(role.id, role)
          guild_role_cache.fetch(payload.id) { Array(UInt64).new }.push(role.id)
        end

        payload.members.each do |member|
          guild_member_cache.cache({payload.id, member.user.id}, member)
          user_cache.cache(member.user.id, member.user)
        end
      end

      on_channel_create do |channel|
        channel_cache.cache(channel.id, channel)
        guild_id = channel.guild_id
        recipients = channel.recipients
        if guild_id
          guild_channel_cache.fetch(guild_id) { Array(UInt64).new }.push(channel.id)
        elsif channel.type.dm? && recipients
          dm_channel_cache.cache(channel.id, recipients[0].id)
        end
      end

      on_channel_update do |channel|
        channel_cache.cache(channel.id, channel)
      end

      on_channel_delete do |channel|
        channel_cache.remove(channel.id)
        if guild_id = channel.guild_id
          guild_channel_cache.resolve?(guild_id).try &.delete(channel.id)
        end
      end

      on_guild_update do |guild|
        guild_cache.cache(guild.id, guild)
      end

      on_guild_delete do |payload|
        guild_cache.remove(payload.id)
      end

      on_guild_member_add do |payload|
        member = GuildMember.new(payload)
        user_cache.cache(member.user.id, member.user)
        guild_member_cache.cache({payload.guild_id, member.user.id}, member)
      end

      on_guild_member_update do |payload|
        user_cache.cache(payload.user.id, payload.user)
        if existing_member = guild_member_cache.resolve?({payload.guild_id, payload.user.id})
          updated_member = GuildMember.new(existing_member, payload.roles, payload.nick)
          guild_member_cache.cache({payload.guild_id, payload.user.id}, updated_member)
        else
          member = get_guild_member(payload.guild_id, payload.user.id)
          guild_member_cache.cache({payload.guild_id, member.user.id}, member)
        end
      end

      on_guild_member_remove do |payload|
        user_cache.cache(payload.user.id, payload.user)
        guild_member_cache.remove({payload.guild_id, payload.user.id})
      end

      on_guild_members_chunk do |payload|
        payload.members.each do |member|
          guild_member_cache.cache({payload.guild_id, member.user.id}, member)
        end
      end

      on_guild_role_create do |payload|
        role_cache.cache(payload.guild_id, payload.role)
        guild_role_cache.fetch(payload.guild_id) { Array(UInt64).new }.push(payload.role.id)
      end

      on_guild_role_update do |payload|
        role_cache.cache(payload.role.id, payload.role)
      end

      on_guild_role_delete do |payload|
        role_cache.remove(payload.role_id)
        guild_role_cache.resolve?(payload.guild_id).try &.delete(payload.role_id)
      end

      on_presence_update do |payload|
        if payload.user.full?
          user = User.new(payload.user)
          user_cache.cache(user.id, user)
          member = GuildMember.new(payload)
          guild_member_cache.cache({payload.guild_id, payload.user.id}, member)
        end
      end
    end
  end
end