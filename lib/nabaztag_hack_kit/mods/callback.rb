
# frozen_string_literal: true

require 'nabaztag_hack_kit/message/api'

module NabaztagHackKit
  module Mods
    module Callback
      module Helpers
        def callback(action, bunny, data, request, run = 0)
          cb = self.class.callbacks[action.to_s]
          return unless cb
          callback = cb[run]
          return unless callback
          instance_exec(bunny, data, request, run, &callback) || callback(action, bunny, data, request, run + 1)
        end
      end

      def on(callback, &block)
        callbacks[callback] ||= []
        callbacks[callback] << block
      end

      def self.registered(app)
        app.helpers Callback::Helpers

        # generic api callback
        %w[get post].each do |method|
          app.send(method, '/api/:bunnyid/:action.jsp') do
            bunny = Bunny.find(params[:bunnyid])
            callback('request', bunny, params, request)
            callback(params[:action], bunny, params, request).tap do |response|
              unless response
                logger.warn "no successful callback found for #{params[:action]}"
                status 404
                break
              end
            end
          end
        end
      end

      def callbacks
        @@callbacks ||= {}
      end
    end
  end
end
