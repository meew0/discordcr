module Discord
  # A `Stack` is a generic container for a chain of middleware.
  #
  # A middleware can be *any* class that implements
  # `def call(payload, context, &block)`.
  #
  # When `#run` is passed a payload, it is passed into the first middleware. If
  # any middleware in the chain does not `yield`, execution of the rest of the
  # chain will stop.
  #
  # `#run` can also be invoked with a block that also accepts the payload and
  # `Context`, which will be called after all middleware successfully run.
  #
  # ```
  # class Middleware
  #   def call(payload, context)
  #     # Make this middleware available in context for later
  #     context.put self
  #
  #     # Do some checks against payload
  #     even = (payload % 2).zero?
  #
  #     # Store some things in context
  #     context.put payload * 2
  #
  #     yield if even
  #   end
  # end
  #
  # stack = Stack.new(Middleware.new)
  # stack.run(2) do |payload, context|
  #   payload        # => 2
  #   context[Int32] # => 4
  # end
  #
  # stack.run(1) do |payload, context|
  #   # Code here is never run!
  # end
  # ```
  #
  # NOTE: While you can implement `Stack` yourself, it is already implemented
  # internally around the `Client` handler methods. The above example is shown
  # for completeness.
  class Stack(*T)
    @middlewares : T

    def initialize(*middlewares : *T)
      @middlewares = middlewares
    end

    # Runs a message through this middleware stack, with a trailing block
    def run(payload : U, context : Context = Context.new, index = 0,
            &block : U, Context ->) forall U
      if mw = @middlewares[index]?
        mw.call(payload, context) { run(payload, context, index + 1, &block) }
      else
        yield payload, context
      end
    end

    # Runs a message through this middleware stack
    def run(payload : U, context : Discord::Context = Context.new,
            index = 0) forall U
      if mw = @middlewares[index]?
        mw.call(payload, context) { run(payload, context, index + 1) }
      end
    end
  end
end
