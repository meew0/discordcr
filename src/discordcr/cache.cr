require "./mappings/*"

# Caches are utility classes that stores various kinds of Discord objects, like `User`s, `Roles`, etc.
# Its purpose is to reduce both the load on Discord's servers and reduce the latency caused by having
# to do an API call. It is recommended to use caching for bots that interact heavily with Discord-provided
# data, like for example administration bots, as opposed to bots that only interact by sending and receiving
# messages. For that latter kind, caching is usually even counter-productive as it only unnecessarily
# increases memory usage.
#
# This modules contains a basic in-memory cache, but also provides interfaces for you to build your own
# custom cache class (see `TypeCache`) that may implement any other kind of store such as Redis or SQL ORDBMS.
module Discord::Cache
  # `TypeCache` is a generic interface that describes behavior for the storage of Discord-related objects.
  # `TypeCache` behavior stores an object `V` by some unique identifier `K` (typically a UInt64 snowflake). 
  # It is up to the user to implement the desired storage behavior.
  # In the implementation of `#init_handlers`, the `TypeCache` is expected to register event handlers on the `Client`
  # reference that will trigger cache-related actions to keep its resources up to date.
  # Alternatively, the `TypeCache` can be used manually without or in addition to handling `Client` events.
  #
  # A simple implementation of an in-memory `Guild` cache may look like:
  # ```
  # class GuildMemory
  #   # Store guilds by their snowflake ID
  #   include Discord::TypeCache(UInt64, Discord::Guild)
  #
  #   # Include the template set of event handlers for guild-related events
  #   include Discord::Handlers::Guild
  #
  #   @guilds = {} of UInt64 => Discord::Guild
  #
  #   def cache(id : UInt64, guild : Discord::Guild)
  #     @guilds[id] = guild
  #   end
  #
  #   def resolve?(id : UInt64)
  #     @guilds[id]?
  #   end
  #
  #   def remove(id : UInt64)
  #     @guilds.delete(id)
  #   end
  # end
  #
  # cache = GuildMemory.new(client)
  # ```
  module TypeCache(K, V)
    # Exception to raise when a member of a cache isn't found
    class MissingMember < Exception
    end

    def initialize(@client : Discord::Client)
      init_handlers
    end

    # Stores the given `object` at `key`.
    abstract def cache(key : K, object : V)

    # Stores the given object, expecting that `object` responds to `#id`.
    def cache(object : V)
      cache(object.id, object)
    end

    # Removes a member from this cache from its `key`.
    abstract def remove(key : K)

    # Removes a member, expecting that `object` responds to `#id`.
    def remove(object : V)
      remove(object.id)
    end

    # Resolves the cache memeber from `key`.
    abstract def resolve?(key : K)

    # Resolves the cache member from `key`.
    # Raises an exception if the member isn't found instead of making a request.
    def resolve(key : K)
      member = resolve?(key)
      raise MissingMember.new("Cache member not present with key: #{key}") unless member

      member
    end

    # Registers handlers on this cache's `Client` to manage its stored data
    abstract def init_handlers
  end

  # Container for multiple `TypeCache` objects that maps Discord types to a `TypeCache`
  class CacheSet
    # The `Client` to pass to the caches to register their handlers on after initialization
    getter client : Client

    def initialize(@client)
    end

    # The different possible cache types
    TYPES = {
      guild:        {key: UInt64, type: Guild},
      guild_member: {key: {UInt64, UInt64}, type: GuildMember},
      channel:      {key: UInt64, type: Channel},
      role:         {key: {UInt64, UInt64}, type: Role},
      users:        {key: UInt64, type: User},
    }

    {% begin %}
      {% for key, properties in TYPES %}
        # Cache for `{{properties[:type]}}` objects
        property {{key}} : TypeCache({{properties[:key]}}, {{properties[:type]}})?

        def [](type : {{properties[:type]}}.class)
          @{{key}}
        end
      {% end %}

      # Assigns multiple `TypeCache` at once
      def configure({{TYPES.map { |key, properties| "#{key} : TypeCache(#{properties[:key]}, #{properties[:type]}).class | Nil = nil".id }.splat}})
        {% for key in TYPES %}
          @{{key}} = {{key}}.try &.new(client)
        {% end %}
      end
    {% end %}
  end

  # This module provides a template set of handlers for easily creating custom `Cache`
  # classes that respond to common gateway events.
  # Each module defines `Cache#init_handlers`.
  module Handlers
    # Handlers for `Guild`-related gateway events.
    module Guild
      def init_handlers
        @client.on_guild_create do |payload|
          guild = Discord::Guild.new(payload)
          cache(guild)
        end

        @client.on_guild_update do |payload|
          cache(payload)
        end

        @client.on_guild_delete do |payload|
          remove(payload.id)
        end
      end
    end

    module GuildMember
      def init_handlers
        @client.on_guild_member_add do |payload|
          new_member = Discord::GuildMember.new(payload)
          cache({payload.guild_id, new_member.user.id}, Discord::GuildMember.new(payload))
        end

        @client.on_guild_members_chunk do |payload|
          payload.members.each do |member|
            cache({payload.guild_id, member.id}, member)
          end
        end

        @client.on_guild_member_update do |payload|
          if existing_member = resolve?({payload.guild_id, payload.user.id})
            new_member = Discord::GuildMember.new(existing_member, payload.roles)
            cache({payload.guild_id, new_member.user.id}, new_member)
          else
            new_member = Discord::GuildMember.new(payload)
            cache({payload.guild_id, new_member.user.id}, Discord::GuildMember.new(payload))
          end
        end

        @client.on_guild_member_remove do |payload|
          remove({payload.guild_id, payload.user.id})
        end

        @client.on_guild_create do |payload|
          payload.members.each do |member|
            cache({payload.id, member.user.id}, member)
          end
        end
      end
    end

    # Handlers for `Role`-related gateway events
    module Role
      def init_handlers
        @client.on_guild_create do |payload|
          payload.roles.each { |role| cache({payload.id, role.id}, role) }
        end

        @client.on_guild_role_create do |payload|
          cache({payload.guild_id, payload.role.id}, payload.role)
        end

        @client.on_guild_role_update do |payload|
          cache({payload.guild_id, payload.role.id}, payload.role)
        end

        @client.on_guild_role_delete do |payload|
          remove({payload.guild_id, payload.role_id})
        end
      end
    end

    # Handlers for `Channel`-related gateway events.
    module Channel
      def init_handlers
        @client.on_guild_create do |payload|
          payload.channels.each { |channel| cache(channel) }
        end

        @client.on_channel_create do |payload|
          cache(payload)
        end

        @client.on_channel_update do |payload|
          cache(payload)
        end

        @client.on_channel_delete do |payload|
          remove(payload.id)
        end
      end
    end

    # Handlers for `Message`-related gateway events.
    module Message
      def init_handlers
        @client.on_message_create do |payload|
          cache(payload)
        end

        @client.on_message_update do |payload|
          cache(payload)
        end

        @client.on_message_delete do |payload|
          remove(payload)
        end
      end
    end
  end
end

require "./cache/*"
