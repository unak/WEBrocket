require "webrick/httpserver"
require "webrocket"

module WEBrick
  class HTTPServer
    def mount_websocket(path, listener, subprotocol)
      mount_proc(path) do |req, res|
        WEBrocket.attach(self, req, res, listener, subprotocol)
      end
    end

    def add_shutdown_listener(prc = nil, &block)
      @shutdown_listeners ||= []
      @shutdown_listeners.push(prc || block)
    end

    alias _original_shutdown shutdown
    def shutdown
      if @shutdown_listeners
        @shutdown_listeners.each do |listener|
          listener.call
        end
      end
      _original_shutdown
    end
  end
end
