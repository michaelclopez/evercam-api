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
      end

      def execute
        camera = Camera.by_exid!(inputs[:id])

        if inputs["schedule"].blank?
          schedule = {}
        else
          begin
            schedule = JSON.parse(inputs["schedule"])
          rescue => _e
            add_error(:schedule, :invalid, "The parameter 'schedule' isn't formatted as a proper JSON.")
          end
        end

        motion_detection = MotionDetection.where(camera_id: camera.id).first

        if motion_detection.blank?
          MotionDetection.create(
            camera: camera,
            frequency: inputs["frequency"],
            minPosition: inputs["minPosition"],
            step: inputs["step"],
            min: inputs["min"],
            threshold: inputs["threshold"],
            schedule: schedule
          )
        else
          motion_detection.update(
            frequency: inputs["frequency"],
            minPosition: inputs["minPosition"],
            step: inputs["step"],
            min: inputs["min"],
            threshold: inputs["threshold"],
            schedule: schedule
          )
          motion_detection
        end
      end
    end
  end
end
