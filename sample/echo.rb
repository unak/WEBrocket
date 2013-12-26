#!ruby
$LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require "webrick"
require "webrocket"

# write listner
class Listener
  def on_open(websocket)
    # do somthing
    p :open
  end

  def on_close(websocket)
    # do somthing
    p :close
  end

  def on_message(websocket, data, type)
    # do something
    p [:message, data, type]
    websocket.send(data, type)
  end

  def on_shutdown
    # do something
    p :shutdown
  end
end

server = WEBrick::HTTPServer.new(Port: 10080)
server.mount_websocket("/echo", Listener.new, "echo")
trap(:INT) do
  server.shutdown
end
server.start
