require "json"
require 'nabaztag_hack_kit/bunny'
require 'nabaztag_hack_kit/message/helper'

module NabaztagHackKit
  module Mods
    module Playground

      def self.registered(app)

        app.get "/" do
          redirect "/playground"
        end

        app.get "/playground" do
          File.read(public_file("index.html"))
        end

        #API
        app.get "/playground/commands" do # return list of commands
          Message::Api.constants.sort.inject({}) do |hash, constant|
            if constant.to_s.length > 2
              hash[constant] = Message::Api.const_get(constant)
            end
            hash
          end.to_json
        end

        app.get "/playground/bunnies" do # return list of bunnies
          Bunny.all.to_json
        end

        app.post "/playground/bunnies/:bunnyid" do #  {"command"=>["40"], "command_values"=>[["1,2,3,4"],[]]}
          if bunny = Bunny.find(params[:bunnyid])
            bunny.queue_commands(Array(params[:command]).zip(params[:command_values]).map do |command, values|
              [command, *values.split(",")]
            end)
            bunny.to_json
          end
        end

        app.post "/playground/bunnies" do #  {"bunny"=>["0019db9c2daf"], "command"=>["40"], "command_values"=>[["1,2,3,4"],[]]}
          Array(params[:bunny]).uniq.each do |bunnyid|
            if bunny = Bunny.find(bunnyid)
              bunny.queue_commands(Array(params[:command]).zip(params[:command_values]).map do |command, values|
                [command, *values.split(",")]
              end)
            end
          end

          redirect "/playground"
        end

        ##################################################################

        app.on "ping" do |bunny|
          if bunny
            bunny.next_message!
          end
        end

        app.on 'request' do |bunny, data|
          if bunny = Bunny.find_or_initialize_by_id(data[:bunnyid])
            bunny.seen!
          end
          nil # pass it on
        end
      end

    end
  end
end
