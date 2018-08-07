#!/bin/bash

# Compile and run the mock server target
shards build
bin/mock_server run &

# Wait for the server to come online
for i in {1..10}; do
  curl -s http://localhost:8080/ping && break || sleep 1
done

# Run specs with client targeted at mock server
crystal spec -Dmock_server
exit_code=$?

# Stop mock server
pkill -f bin/mock_server

# Return specs exit code
exit $exit_code
