require "./spec_helper"
require "./mock_server"

def run_request(on server, with request)
  io = IO::Memory.new
  server_response = HTTP::Server::Response.new(io)
  context = HTTP::Server::Context.new(request, server_response)
  server.handle(context)
  io.rewind
  HTTP::Client::Response.from_io(io)
end

describe Discord::MockServer do
  server = Discord::MockServer.new

  it "gets endpoints" do
    endpoint = server.add "GET", "/ping", 200,
      {"Content-Type" => "text/plain"}, "pong"
    request = HTTP::Request.new("GET", "/_endpoints")

    response = run_request(on: server, with: request)
    response.status_code.should eq 200
    response.body.should eq [endpoint].to_json
  end

  it "creates endpoints" do
    endpoint = Discord::MockServer::Endpoint.new("GET", "/ping", 200,
      {"Content-Type" => "text/plain"}, "pong")
    json = endpoint.to_json
    request = HTTP::Request.new("POST", "/_endpoints",
      HTTP::Headers{"Content-Type" => "application/json"}, json)

    response = run_request(on: server, with: request)
    response.status_code.should eq 201
    response.body.should eq json
  end

  it "responds with 404 on missing route" do
    request = HTTP::Request.new("GET", "/unknown")
    response = run_request(on: server, with: request)
    response.status_code.should eq 404
    response.body.should eq "404 Not Found\n"
  end
end
