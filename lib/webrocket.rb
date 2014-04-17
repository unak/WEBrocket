require "base64"
require "digest/sha1"
require "webrocket/webrick-extender"
require "webrocket/websocket"
require "webrocket/version"

module WEBrocket
  def self.attach(server, req, res, listener, subprotocol)
    key = req["Sec-WebSocket-Key"]
    unless key
      res.status = WEBrick::HTTPStatus::RC_BAD_REQUEST
      return
    end
    key += "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
    res["Sec-WebSocket-Accept"] = Base64.strict_encode64(Digest::SHA1.digest(key))

    if req["Sec-WebSocket-Version"].to_i < 13
      res.status = WEBrick::HTTPStatus::RC_BAD_REQUEST
      res["Sec-WebSocket-Version"] = 13
      return
    end

    if req["Sec-WebSocket-Protocol"]
      protocols = req["Sec-WebSocket-Protocol"].split(/\s*,\s*/)
      if protocols.include?(subprotocol)
        res["Sec-WebSocket-Protocol"] = subprotocol
      elsif protocols.include?("null")
        res["Sec-WebSocket-Protocol"] = "null"
      end
    end

    res.status = WEBrick::HTTPStatus::RC_SWITCHING_PROTOCOLS
    res["Upgrade"] = "websocket"
    #res["Connection"] = "Upgrade"

    @keep_alive = true

    res.define_singleton_method(:send_response) do |sock|
      begin
        setup_header
        @header["connection"] = "Upgrade"
        send_header(sock)
        ws = WEBrocket::WebSocket.new(sock, listener, subprotocol)
        server.add_shutdown_listener(ws.method(:on_shutdown))
        ws.start
        @keep_alive = false
      rescue Errno::EPIPE, Errno::ECONNRESET, Errno::ENOTCONN => ex
        @logger.debug(ex)
        @keep_alive = false
      rescue StandardError => ex
        @logger.error(ex)
        @keep_alive = false
      end
    end
  end
end
