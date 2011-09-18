require 'eventmachine'
require "http/parser"
require 'webrick/httpresponse'
require 'webmachine/version'
require 'webmachine/headers'
require 'webmachine/request'
require 'webmachine/response'
require 'webmachine/dispatcher'

module Webmachine
  module Adapters
    module EventMachine
      # Starts the Mongrel adapter
      def self.run
        c = Webmachine.configuration
        trap("INT"){ ::EventMachine::stop_event_loop }

        ::EventMachine::run {
          ::EventMachine.start_server c.ip, c.port, HttpServer
        }
      end

      module HttpServer
        def post_init
          puts "-- someone connected to the server!"

          @parser = ::Http::Parser.new
          @parser.on_body = proc { |chunk| @body << chunk }
          @parser.on_message_complete = proc do
            request = Webmachine::Request.new(@parser.http_method,
                                            URI.parse(@parser.request_url),
                                            @parser.headers,
                                            @body || StringIO.new(''))

            response = Webmachine::Response.new
            Webmachine::Dispatcher.dispatch(request, response)

            r = ::WEBrick::HTTPResponse.new({
              :HTTPVersion => @parser.http_version.join('.')
            })

            r.status = response.code.to_i
            r.header.replace response.headers
            r.header["Server"] = Webmachine::SERVER_STRING
            r.body = response.body

            send_data r
          end
        end

        def receive_data data
          @parser << data
        end

        def unbind
          puts "-- someone disconnected from the server!"
        end
      end
    end
  end
end
