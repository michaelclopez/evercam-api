require 'stringio'

module Evercam
  module Actors
    class MotionDetectionUpdate < Mutations::Command
      required do
        string :id
      end

      optional do
        integer :frequency
        integer :minPosition
        integer :step
        integer :min
        integer :threshold
        boolean :enabled
        boolean :alert_email
        integer :alert_interval_min, :empty => true
        integer :sensitivity, :empty => true
        integer :x1, :empty => true
        integer :x2, :empty => true
        integer :y1, :empty => true
        integer :y2, :empty => true
        string :schedule
      end

      def validate
        unless Camera.by_exid(id)
          add_error(:camera, :exists, 'Camera does not exist')
        end

        unless inputs["schedule"].blank?
          begin
            JSON.parse(inputs["schedule"])
          rescue => _e
            add_error(:schedule, :invalid, "The parameter 'schedule' isn't formatted as a proper JSON.")
          end
        end
      end

      def execute
        camera = Camera.by_exid!(inputs[:id])
        if camera.nil?
          raise Evercam::NotFoundError.new("A camera with the id '#{inputs[:id]}' does not exist.",
                                           "camera_not_exist_error", inputs[:id])
        end

        motion_detection = ::MotionDetection.where(camera_id: camera.id).first

        if motion_detection.nil?
          raise Evercam::NotFoundError.new("Camera does not have motion detection settings.",
                                           "motion_detection_not_exist_error", inputs[:id])
        end

        motion_detection.frequency = frequency if frequency
        motion_detection.minPosition = minPosition if minPosition
        motion_detection.step = step if step
        motion_detection.min = min if min
        motion_detection.threshold = threshold if threshold
        motion_detection.enabled = enabled unless enabled.nil?

        motion_detection.alert_email = alert_email if alert_email
        motion_detection.alert_interval_min = alert_interval_min if alert_interval_min
        motion_detection.sensitivity = sensitivity if sensitivity
        motion_detection.x1 = x1 if x1
        motion_detection.x2 = x2 if x2
        motion_detection.y1 = y1 if y1
        motion_detection.y2 = y2 if y2
        motion_detection.schedule = JSON.parse(inputs["schedule"]) if schedule
        motion_detection.save

        motion_detection
      end
    end
  end
end
