require 'stringio'

module Evercam
  module Actors
    class MotionDetectionEmailDelete < Mutations::Command
      required do
        string :id
        string :email
      end

      def validate
        unless Camera.by_exid(id)
          add_error(:camera, :exists, 'Camera does not exist')
        end
      end

      def execute
        camera = ::Camera.by_exid(inputs[:id])
        if camera.values[:config].has_key?('motion')
          if camera.values[:config]['motion'].has_key?('emails')
            camera.values[:config]['motion']["emails"].delete(inputs["email"])
          else
            raise NotFoundError.new("Unable to locate email '#{inputs[:email]}'.",
                                    "email_not_found_error", inputs[:email])
          end
        else
          raise NotFoundError.new("Unable to locate email '#{inputs[:email]}'.",
                                  "email_not_found_error", inputs[:email])
        end

        camera.save

        camera
      end
    end
  end
end
