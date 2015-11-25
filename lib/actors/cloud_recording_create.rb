module Evercam
  module Actors
    class CloudRecordingCreate < Mutations::Command

      required do
        string :id
      end

      optional do
        integer :frequency
        integer :storage_duration
        string :status
        string :schedule
      end

      def execute
        camera = Camera.by_exid!(inputs[:id])

        unless ["off", "on", "on-scheduled"].include? inputs["status"]
          add_error(:status, :invalid, "The parameter 'status' isn't valid.")
        end

        if inputs["schedule"].blank?
          schedule = {}
        else
          begin
            schedule = JSON.parse(inputs["schedule"])
          rescue => _e
            add_error(:schedule, :invalid, "The parameter 'schedule' isn't formatted as a proper JSON.")
          end
        end

        cloud_recording = CloudRecording.where(camera_id: camera.id).first

        if cloud_recording.blank?
          CloudRecording.create(
            camera: camera,
            frequency: inputs["frequency"],
            storage_duration: inputs["storage_duration"],
            status: inputs["status"],
            schedule: schedule
          )
        else
          cloud_recording.update(
            frequency: inputs["frequency"],
            storage_duration: inputs["storage_duration"],
            status: inputs["status"],
            schedule: schedule
          )
          cloud_recording
        end
      end
    end
  end
end
