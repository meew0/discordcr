module Discord
  abstract class Cache(K, V)
    class Error < Exception
    end

    abstract def resolve?(key : K)

    def fetch(key : K) : V
      resolve?(key) || cache(key, yield)
    end

    def resolve(key : K) : V
      resolve?(key) || raise Error.new("Cache member not found: #{key}")
    end

    abstract def cache(key : K, value : V)

    abstract def remove(key : K)

    abstract def each(&block : Tuple(K, V) ->)
  end

  class MemoryCache(K, V) < Cache(K, V)
    include Enumerable(Tuple(K, V))

    def initialize
      @cache = {} of K => V
    end

    def each(&block : Tuple(K, V) ->)
      @cache.each do |key, value|
        yield({key, value})
      end
    end

    def resolve?(key : K)
      @cache[key]?
    end

    def cache(key : K, value : V)
      @cache[key] = value
    end

    def remove(key : K)
      @cache.delete(key)
    end
  end

  class NullCache(K, V) < Cache(K, V)
    def resolve?(key : K)
      nil
    end

    def cache(key : K, value : V)
      value
    end

    def remove(key : K)
      nil
    end

    def each(&block : Tuple(K, V) ->)
      nil
    end
  end
end
