require "./spec_helper"

class TestMiddleware
  property called = false

  def initialize(@should_yield = true)
  end

  def call(payload : Int32, context)
    @called = true
    yield if @should_yield
  end

  def call(payload : String, context)
    @called = true
    yield if @should_yield
  end
end

describe Discord::Stack do
  describe "#run" do
    it "calls each middleware" do
      middlewares = {TestMiddleware.new, TestMiddleware.new}
      stack = Discord::Stack.new(*middlewares)
      stack.run(1, Discord::Context.new)

      middlewares.each do |mw|
        mw.called.should be_true
      end
    end

    it "runs middleware handles multiple kinds of events" do
      middleware = TestMiddleware.new
      stack = Discord::Stack.new(middleware)

      stack.run(1)
      middleware.called.should be_true
      middleware.called = false

      stack.run("foo")
      middleware.called.should be_true
    end

    it "stops when a middleware doesn't yield" do
      middlewares = {
        TestMiddleware.new,
        TestMiddleware.new(false),
        TestMiddleware.new,
      }
      stack = Discord::Stack.new(*middlewares)

      stack.run(1)
      middlewares[0].called.should be_true
      middlewares[1].called.should be_true
      middlewares[2].called.should be_false
    end

    it "accepts a block" do
      stack = Discord::Stack.new(TestMiddleware.new)

      ran = false
      stack.run(1) do
        ran = true
      end

      ran.should be_true
    end
  end
end
