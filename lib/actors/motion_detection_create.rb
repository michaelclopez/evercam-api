module Evercam
  module Actors
    class MotionDetectionCreate < Mutations::Command
      required do
        string :id
      end

      optional do
        integer :frequency
        integer :minPosition
        integer :step
        integer :min
        integer :threshold
        string :schedule
        boolean :enabled
        boolean :alert_email
        integer :alert_interval_min
        integer :sensitivity
        integer :x1
        integer :x2
        integer :y1
        integer :y2
        string :email
      end

      def validate
        if inputs["schedule"].present?
          begin
            JSON.parse(inputs["schedule"])
          rescue => _e
            add_error(:schedule, :invalid, "The parameter 'schedule' isn't formatted as a proper JSON.")
          end
        end
      end

      def execute
        camera = Camera.by_exid!(inputs[:id])

        if inputs["schedule"].blank?
          schedule = {}
        else
          schedule = JSON.parse(inputs["schedule"])
        end
        if inputs["email"].blank?
          emails = []
        else
          emails = []
          emails.push(inputs["email"])
        end

        if MotionDetection.where(camera_id: camera.id).count != 0
          raise Evercam::ConflictError.new("The Motion Detection settings already exist for camera '#{inputs[:id]}'.",
                                           "duplicate_camera_id_error", inputs[:id])
        end

        motion_detection =  MotionDetection.new(
          camera: camera,
          schedule: schedule
        )
        motion_detection.frequency = frequency if frequency
        motion_detection.minPosition = minPosition if minPosition
        motion_detection.step = step if step
        motion_detection.min = min if min
        motion_detection.threshold = threshold if threshold
        motion_detection.enabled = enabled if enabled

        motion_detection.alert_email = alert_email if alert_email
        motion_detection.alert_interval_min = alert_interval_min if alert_interval_min
        motion_detection.sensitivity = sensitivity if sensitivity
        motion_detection.x1 = x1 if x1
        motion_detection.x2 = x2 if x2
        motion_detection.y1 = y1 if y1
        motion_detection.y2 = y2 if y2
        motion_detection.emails = emails
        motion_detection.save
        motion_detection
      end
    end
  end
end
