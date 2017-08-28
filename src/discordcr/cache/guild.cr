module Discord::Cache
  module Memory
    class Guild
      # Store guilds by their snowflake ID
      include TypeCache(UInt64, Discord::Guild)

      # Include the template set of event handlers for guild-related events
      include Handlers::Guild

      @guilds = {} of UInt64 => Discord::Guild

      def cache(id : UInt64, guild : Discord::Guild)
        Discord::LOGGER.info("Caching guild: #{id} (#{@guilds.size})")
        @guilds[id] = guild
      end

      def resolve?(id : UInt64)
        Discord::LOGGER.info("Resolving guild: #{id} (#{@guilds.size})")
        @guilds[id]?
      end

      def remove(id : UInt64)
        Discord::LOGGER.info("Removing guild: #{id} (#{@guilds.size})")
        @guilds.delete(id)
      end
    end

    class GuildMember
      # Store guilds by their snowflake ID
      include TypeCache({UInt64, UInt64}, Discord::GuildMember)

      # Include the template set of event handlers for guild-related events
      include Handlers::GuildMember

      @guild_members = {} of {UInt64, UInt64} => Discord::GuildMember
      @guild_members_map = Hash(UInt64, Set(UInt64)).new(Set(UInt64).new)

      def cache(id : {UInt64, UInt64}, member : Discord::GuildMember)
        Discord::LOGGER.info("Caching guild_member: #{id} (#{@guild_members.size})")
        @guild_members_map[id[0]].add(id[1])
        @guild_members[id] = member
      end

      def resolve?(id : {UInt64, UInt64})
        Discord::LOGGER.info("Resolving guild_member: #{id}")
        @guild_members[id]?
      end

      def resolve(guild_id : UInt64)
        @guild_members_map[guild_id].map { |id| resolve?({guild_id, id}) }
      end

      def remove(id : {UInt64, UInt64})
        Discord::LOGGER.info("Removing guild_member: #{id}")
        @guild_members_map[id[0]].delete(id[1])
        @guild_members.delete(id)
      end
    end

    class Role
      # Store guilds by their snowflake ID
      include TypeCache({UInt64, UInt64}, Discord::Role)

      # Include the template set of event handlers for guild-related events
      include Handlers::Role

      @roles = {} of {UInt64, UInt64} => Discord::Role
      @guild_role_map = Hash(UInt64, Set(UInt64)).new(Set(UInt64).new)

      def cache(id : {UInt64, UInt64}, role : Discord::Role)
        Discord::LOGGER.info("Caching role: #{id} (#{@roles.size})")
        @guild_role_map[id[0]].add(id[1])
        @roles[id] = role
      end

      def resolve?(id : {UInt64, UInt64})
        Discord::LOGGER.info("Resolving role: #{id}")
        @roles[id]?
      end

      def resolve(guild_id : UInt64)
        Discord::LOGGER.info("Resolving roles for guild: #{guild_id}")
        @guild_role_map[guild_id].map { |id| resolve?({guild_id, id}) }
      end

      def remove(id : {UInt64, UInt64})
        Discord::LOGGER.info("Removing role: #{id}")
        @guild_role_map[id[0]].delete(id[1])
        @roles.delete(id)
      end
    end
  end
end
