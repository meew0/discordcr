module Discord
  # A `Context` instance is a container that can be used to store any kind of
  # class to be later recalled:
  # ```
  # class Foo
  #   getter value
  #
  #   def initialize(@value : Int32)
  #   end
  # end
  #
  # class Bar
  #   getter value
  #
  #   def initialize(@value : String)
  #   end
  # end
  #
  # context = Context.new
  # context.put Foo.new(1337)
  # context.put Bar.new("discord")
  #
  # context[Foo].value # => 1337
  # context[Bar].value # => "discord"
  # ```
  class Context
    @extensions = Hash(Int32, Void*).new

    # Access a stored value by class
    def [](clazz : T.class) : T forall T
      if reference = @extensions[clazz.crystal_type_id]?
        reference.unsafe_as(T)
      else
        raise KeyError.new("Missing reference in context to #{T}")
      end
    end

    # Store an object in this class. The object must be a `class`.
    def put(extension : T) forall T
      {% raise "Extension must be a class" unless T < Reference %}
      raise "BUG: Reference isn't sizeof(Void*)!" unless sizeof(typeof(extension)) == sizeof(Void*)
      @extensions[extension.class.crystal_type_id] = extension.unsafe_as(Pointer(Void))
    end
  end
end
