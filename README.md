WEBRocket
=========

WebSocket extension for WEBrick.
This library is under development.


Requirements
------------

+ Ruby 1.9.3 or later.


Installation
------------

Add this line to your application's Gemfile:

  gem 'WEBrocket'

And then execute:

  $ bundle

Or install it yourself as:

  $ gem install WEBrocket


How to use
----------

  require "webrick"
  require "webrocket"
  
  # write listner
  class Listener
    def on_open(websocket)
      # do somthing
    end
  
    def on_close(websocket)
      # do somthing
    end
  
    def on_recv(websocket, data, type)
      # do something
    end
  
    def on_shutdown
      # do something
    end
  end
  
  server = WEBrick::HTTPServer.new
  server.mount_websocket("sample", Listener.new, "test")
  server.start

See sample directory for more details.


License
-------

Copyright (c) 2013 NAKAMURA Usaku usa@garbagecollect.jp

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


Supplimentary
-------------

I've found that there are many projects named webrocket, but, sorry, I can't
stop naming this one the same name :)
