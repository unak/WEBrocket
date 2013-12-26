#!ruby
$LOAD_PATH.unshift(File.expand_path("../lib", File.dirname(__FILE__)))
require "webrick"
require "webrocket"

# write listner
class Listener
  def initialize
    @clients = []
    @m = Mutex.new
  end

  def on_open(websocket)
    p [:open, websocket]
    @m.synchronize do
      @clients.push(websocket)
    end
  end

  def on_close(websocket)
    p [:close, websocket]
    @m.synchronize do
      user = websocket.instance_variable_get(:@chat_user)
      if user
        @clients.each do |cl|
          cl.send("logout #{user}", :text)
        end
      end
      @clients.delete(websocket)
    end
  end

  def on_message(websocket, data, type)
    user = websocket.instance_variable_get(:@chat_user)
    @m.synchronize do
      @clients.each do |cl|
        if user
          cl.send("#{user}: #{data}", :text)
        else
          cl.send("login #{data}", :text)
        end
      end
    end
    unless user
      websocket.instance_variable_set(:@chat_user, data)
    end
  end

  def on_shutdown
    p [:shutdown]
    # nothing to do
  end
end

server = WEBrick::HTTPServer.new(Port: 10080)
server.mount_websocket("/chat", Listener.new, "chat")
trap(:INT) do
  server.shutdown
end
server.start
