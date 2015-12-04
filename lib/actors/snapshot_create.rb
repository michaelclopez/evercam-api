# Disable File validation, it doesn't work
module Mutations
  class FileFilter < AdditionalFilter
    alias_method :filter_old, :filter

    def filter(data)
      [data, nil]
    end
  end
end

module Evercam
  module Actors
    class SnapshotCreate < Mutations::Command
      required do
        string :id
        integer :timestamp
        file :data, upload: true
      end

      optional do
        string :notes
      end

      def validate
        if Snapshot.snapshot_by_ts(Camera.by_exid(id).id, Time.at(timestamp.to_i))
          add_error(:snapshot, :exists, 'Snapshot for this timestamp already exists')
        end
      end

      def execute
        camera = ::Camera.by_exid!(id)
        unless %w(image/jpeg image/pjpeg image/png image/x-png image/gif).include? inputs[:data]['type']
          raise Evercam::WebErrors::BadRequestError.new(message="File not provided or file type not supported", code="invalid_parameters", context="data")
        end
        filepath = "#{camera.exid}/snapshots/#{timestamp.to_i}.jpg"
        Services::snapshot_bucket.objects.create(filepath, inputs[:data]['tempfile'].read)

        Snapshot.create(
          camera_id: camera.id,
          created_at: Time.at(timestamp).utc,
          notes: notes,
          snapshot_id: "#{camera.id}_#{Time.at(timestamp).strftime("%Y%m%d%H%M%S%L")}"
        )
      end
    end
  end
end
