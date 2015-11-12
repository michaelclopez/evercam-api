require 'stringio'

module Evercam
  module Actors
    class MotionDetectionEmailCreate < Mutations::Command
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
            if camera.values[:config]['motion']["emails"].include?(inputs["email"])
              raise Evercam::ConflictError.new("The email '#{inputs[:email]}' is already exist.",
                                      "duplicate_email_error", inputs[:email])
            end
            camera.values[:config]['motion']["emails"].push(inputs["email"])
          else
            camera.values[:config].merge!('motion' => { "emails" => [] })
            camera.values[:config]['motion']["emails"].push(inputs["email"])
          end
        else
          camera.values[:config].merge!('motion' => { "emails" => [] })
          camera.values[:config]['motion']["emails"].push(inputs["email"])
        end

        camera.save

        camera
      end
    end
  end
end
