require "webrocket"

module WEBrocket
  class WebSocket
    class InternalError < StandardError; end

    OP_CONTINUE = 0x0
    OP_TEXT = 0x1
    OP_BINARY = 0x2
    OP_CLOSE = 0x8
    OP_PING = 0x9
    OP_PONG = 0xA

    CLOSE_OK = [1000].pack("n")
    CLOSE_CLOSED = [1001].pack("n")
    CLOSE_PROTOCOL_ERROR = [1002].pack("n")
    CLOSE_BROKEN_DATA = [1003].pack("n")
    CLOSE_BROKEN_MESSAGE = [1007].pack("n")
    CLOSE_POLICY_ERROR = [1008].pack("n")
    CLOSE_TOO_BIG = [1009].pack("n")
    CLOSE_UNKNOWN_ERROR = [1011].pack("n")

    def initialize(sock, listener, subprotocol)
      @sock = sock
      @listener = listener
      @subprotocol = subprotocol
      @type = nil
      @reason = nil
    end

    attr_reader :subprotocol

    def start
      @listener.on_open(self) if @listener.respond_to?(:on_open)
      begin
        while true
          r = IO.select([@sock])
          recv_frame if r
        end
      rescue IOError
        @reason ||= CLOSE_CLOSED
      ensure
        @reason ||= CLOSE_UNKNOWN_ERROR
        send_close_frame(@reason) unless @sock.closed?
        @listener.on_close(self) if @listener.respond_to?(:on_close)
      end
    end

    def send(data, type = :text)
      nil until IO.select([], [@sock])
      case type
      when :text
        op = OP_TEXT
      when :binary
        op = OP_BINARY
      else
        raise InternalError, "unknown type: #{type}"
      end
      send_frame(op, data)
    end

    def on_shutdown
      send_close_frame unless @sock.closed?
      @listener.on_shutdown if @listener.respond_to?(:on_shutdown)
    end

    private
    def send_close_frame(data = "")
      send_frame(OP_CLOSE, data)
    end

    def send_frame(opcode, data = "")
      data = data.dup.force_encoding('binary')
      if data.bytesize <= 125
        @sock.write([0x80 | opcode, data.bytesize].pack("cc") + data)
      elsif data.bytesize <= 0xffff
        @sock.write([0x80 | opcode, 126, data.bytesize].pack("ccn") + data)
      else # under 64bit
        @sock.write([0x80 | opcode, 127, data.bytesize / 0x1_0000_0000, data.bytesize % 0x1_0000_0000].pack("ccNN") + data)
      end
    end

    def recv_frame
      header = @sock.read(2)
      return unless header
      if header.bytesize != 2
        @reason = CLOSE_PROTOCOL_ERROR
        raise InternalError, "something wrong: header = '#{header}'"
      end
      h0, h1 = header.unpack("cc")
      len = h1 & 0x7F
      if len == 126
        tmp = @sock.read(2)
        if !tmp || tmp.bytesize != 2
          @reason = CLOSE_PROTOCOL_ERROR
          raise InternalError, "something wrong: size = '#{tmp}'"
        end
        len = tmp.unpack("n")
      elsif len == 127
        tmp = @sock.read(8)
        if !tmp || tmp.bytesize != 8
          @reason = CLOSE_PROTOCOL_ERROR
          raise InternalError, "something wrong: size = '#{tmp}'"
        end
        l0, l1 = tmp.unpack("NN")
        len = l0 * 0x1_0000_0000 + l1
      end
      if len > 0
        if h1 & 0x80 != 0
          key = @sock.read(4)
          if !key || key.bytesize != 4
            @reason = CLOSE_PROTOCOL_ERROR
            raise InternalError, "something wrong: key = '#{key}'"
          end
        end

        data = @sock.read(len)
        if !data || data.bytesize != len
          @reason = CLOSE_PROTOCOL_ERROR
          raise InternalError, "something wrong"
        end

        if h1 & 0x80 != 0
          data = data.bytes.map.with_index{|b, i| (b ^ (key[i % 4].ord)).chr}.join
        end
      end

      op = h0 & 0xF

      if h0 & 0x80 == 0
        # XXX
        @reason = CLOSE_TOO_BIG
        raise InternalError, "fragmented data is not supported yet"
      end

      case op
      when OP_CONTINUE, OP_TEXT, OP_BINARY
        if op == OP_TEXT
          @type = :text
        elsif op == OP_BINARY
          @type = :binary
        elsif !@type
          @reason = CLOSE_PROTOCOL_ERROR
          raise InternalError, "continued data at the first"
        end
        if @type == :text
          data.force_encoding('utf-8')
          raise InternalError, "invalid encoding" unless data.valid_encoding?
        end
        @listener.on_message(self, data, @type) if @listener.respond_to?(:on_message)
      when OP_CLOSE
        @reason = CLOSE_OK
        raise IOError
      when OP_PING
        send_frame(OP_PONG, data)
      when OP_PONG
        # nothing to do
      else
        @reason = CLOSE_PROTOCOL_ERROR
        raise InternalError, "unknown opcode: 0x%x" % op
      end
    end
  end
end
