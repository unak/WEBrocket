require 'base64'
require 'net/http'
require 'socket'
require 'test/unit'
require 'webrick'
$LOAD_PATH.unshift(File.expand_path('../lib', File.dirname(__FILE__)))
require 'webrocket'

class TestWEBrocket < Test::Unit::TestCase
  def start_test_server(&block)
    logger = Object.new
    logger.instance_eval do
      def <<(msg)
        @log ||= ''
        @log << msg
      end

      def log
        @log ||= ''
      end
    end

    server = WEBrick::HTTPServer.new(
      :BindAddress => "127.0.0.1",
      :Port => 0,
      :DocumentRoot => File.dirname(__FILE__),
      :ShutdownSocketWithoutClose => true,
      :ServerType => Thread,
      :Logger => WEBrick::Log.new(logger),
      :AccessLog => [[logger, ""]]
    )

    begin
      th = server.start
      addr = server.listeners[0].addr
      block.call(server, addr[3], addr[1], logger)
    ensure
      server.shutdown
      th.join
    end

    logger.log
  end

  class Listener
    def initialize(open = proc{}, close = proc{}, message = proc{}, shutdown = proc{})
      @open = open
      @close = close
      @message = message
      @shutdown = shutdown
    end

    def on_open(websocket)
      @open.call(websocket)
    end

    def on_close(websocket)
      @close.call(websocket)
    end

    def on_message(websocket, data, type)
      @message.call(websocket, data, type)
    end

    def on_shutdown
      @shutdown.call
    end
  end

  def test_websocket
    shutdowned = false # yes, I know shutdown is a noun
    start_test_server do |server, host, port, logger|
      http = Net::HTTP.new(host, port)

      req = Net::HTTP::Get.new('/')
      http.request(req) do |res|
        assert_kind_of Net::HTTPOK, res.response
      end

      opened = false
      open = lambda {|websocket|
        opened = true
      }
      close = lambda {|websocket|
        opened = false
      }
      message = lambda {|websocket, data, type|
      }
      shutdown = lambda {
        shutdowned = true
      }
      server.mount_websocket('/test', Listener.new(open, close, message, shutdown), 'test')

      req = Net::HTTP::Get.new('/test')
      req['Upgrade'] = 'websocket'
      req['Connection'] = 'Upgrade'
      req['Sec-WebSocket-Version'] = '13'
      req['Sec-WebSocket-Key'] = Base64.encode64('0'*16)

      refute opened
      sock = nil
      http.request(req) do |res|
        assert_kind_of Net::HTTPSwitchProtocol, res.response
        sock = http.instance_variable_get(:@socket).io.dup
      end

      assert opened

      sock.shutdown

      refute shutdowned
    end
    assert shutdowned
  end
end
