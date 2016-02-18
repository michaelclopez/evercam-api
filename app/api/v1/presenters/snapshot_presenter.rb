require_relative './presenter'
require 'base64'

module Evercam
  module Presenters
    class Snapshot < Presenter
      root :snapshots

      expose :created_at, documentation: {
        type: 'integer',
        desc: 'Snapshot timestamp',
        required: false
      } do |snapshot, _options|
        snapshot.created_at.to_i
      end

      expose :notes, documentation: {
        type: 'string',
        desc: 'Note for snapshot',
        required: false
      }

      expose :motion_level, documentation: {
        type: 'integer',
        desc: 'Snapshot motion level',
        required: false
      } do |snapshot, _options|
        snapshot.motionlevel
      end

      expose :data, if: { with_data: true }, documentation: {
        type: 'file',
        desc: 'Image data',
        required: false
      } do |snapshot, options|
        filepath = "#{options[:exid]}/snapshots/#{snapshot.created_at.to_i}.jpg"
        s3_object = Evercam::Services.snapshot_bucket.objects[filepath]
        if s3_object.exists?
          image = s3_object.read
        else
          url = "#{Evercam::Config[:snapshots][:url]}v1/cameras/#{options[:exid]}/recordings/snapshots/#{snapshot.snapshot_id}"
          conn = Faraday.new(url: url) do |faraday|
            faraday.adapter Faraday.default_adapter
          end
          response = conn.get
          image = response.body
        end
        data = Base64.encode64(image).gsub("\n", '')
        "data:image/jpeg;base64,#{data}"
      end
    end
  end
end
