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
        camera = Camera.by_exid!(inputs[:id])
        raise Evercam::ConflictError.new("A camera with the id '#{inputs[:id]}' does not exist.",
                                         "camera_not_exist_error", inputs[:id]) if camera.nil?

        motion_detection = ::MotionDetection.where(camera_id: camera.id).first
        raise Evercam::NotFoundError.new("Camera does not have motion detection settings.",
                                         "motion_detection_not_exist_error", inputs[:id]) if motion_detection.nil?


        motion_detection.emails.delete(inputs["email"])
        motion_detection.save
      end
    end
  end
end
