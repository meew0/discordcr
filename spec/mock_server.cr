require "http/server"
require "json"
require "logger"

# TODO: docs
class Discord::MockServer
  record(Endpoint, method : String, path : String, status_code : Int32,
    headers : Hash(String, String)?, body : String) do
    include JSON::Serializable

    def id
      {method, path}
    end
  end

  def self.prepare_endpoint(*args, **kwargs)
    endpoint = Endpoint.new(*args, **kwargs)
    HTTP::Client.post("http://localhost:8080/_endpoints",
      HTTP::Headers{"Content-Type" => "application/json"},
      endpoint.to_json)
  end

  def initialize
    @http_server = HTTP::Server.new do |context|
      handle(context)
    end
    @logger = Logger.new(STDOUT)
    @logger.progname = "mock server"
    @endpoints = Hash({String, String}, Endpoint).new
  end

  def run
    # TODO: Config port
    @logger.info("Listening on localhost:8080")
    @http_server.bind_tcp 8080
    @http_server.listen
  end

  def handle(context : HTTP::Server::Context)
    log(context.request)
    request, response = context.request, context.response
    route = {request.method, request.path}
    handled = false

    begin
      case {request.method, request.path}
      when {"GET", "/_endpoints"}
        respond_json(@endpoints.values.to_json, 200, response)
        handled = true
      when {"POST", "/_endpoints"}
        endpoint = Endpoint.from_json(request.body || "")
        @endpoints[endpoint.id] = endpoint
        respond_json(endpoint.to_json, 201, response)
        handled = true
      else
        if endpoint = @endpoints[route]?
          respond_endpoint(endpoint, response)
          handled = true
        end
      end

      unless handled
        response.respond_with_error("Not Found", 404)
      end
    rescue ex
      response.respond_with_error("Internal Server Error", 500)
      raise ex
    ensure
      response.close
    end
  end

  # :nodoc:
  def add(*args, **kwargs)
    endpoint = Endpoint.new(*args, **kwargs)
    @endpoints[endpoint.id] = endpoint
  end

  private def log(request : HTTP::Request)
    @logger.info("[IN] #{request.method} #{request.path}")
  end

  private def respond_json(body, status_code, response)
    response.content_type = "application/json"
    response.status_code = status_code
    response.content_length = body.bytesize
    response.print(body)
  end

  private def respond_endpoint(endpoint, response)
    endpoint.headers.try &.each do |key, value|
      response.headers.add(key, value)
    end
    response.status_code = endpoint.status_code
    response.content_length = endpoint.body.bytesize
    response.print(endpoint.body)
  end
end

# TODO: make nicer
if ARGV[0]? == "run"
  server = Discord::MockServer.new
  server.add("GET", "/ping", 200, {"Content-Type" => "text/plain"}, "pong")
  server.run
end
