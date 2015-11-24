require_relative './presenter'

module Evercam
  module Presenters
    class Log < Presenter

      root :logs

      expose :who, documentation: {
        type: 'string',
        desc: 'Username or Client name ',
        required: true
      } do |c,o|
        if c.name.nil?
          "Anonymous"
        else
          c.name
        end
      end

      expose :action, documentation: {
        type: 'string',
        desc: 'Camera action',
        required: true
      }

      with_options(format_with: :timestamp) do
        expose :done_at, documentation: {
          type: 'integer',
          desc: 'Unix timestamp of the action',
          required: true
        }
      end

      expose :extra, documentation: {
        type: 'string',
        desc: 'Camera action',
        required: true
      } do |c,o|
        unless c.extra.nil? or c.extra['with'].nil?
          user = ::User.by_login(c.extra['with'])
          unless user.nil?
            c.extra['with'] = user.fullname if user.fullname.nil?
          end
        end
        c.extra
      end

    end
  end
end

