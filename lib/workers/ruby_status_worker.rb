require 'aws'
require_relative '../../lib/services'

module Evercam
  class RubyStatusWorker

    include Sidekiq::Worker

    sidekiq_options queue: :status

    def perform(camera_id, status, timestamp)
      camera = Camera.by_exid!(camera_id)

      if camera.is_online == status
        camera.last_polled_at = Time.at(timestamp)
        camera.save
      else
        camera.is_online = status
        camera.last_polled_at = Time.at(timestamp)
        camera.last_online_at = Time.at(timestamp) if status == true
        camera.save

        CameraActivity.create(
          camera_id: camera.id,
          camera_exid: camera.exid,
          access_token: nil,
          name: nil,
          action: status,
          done_at: Time.at(timestamp).utc,
          ip: nil
        )

        CacheInvalidationWorker.enqueue(camera.exid)

        logger.info("Update for camera #{camera.exid} finished. New status #{status}")
      end
    end
  end
end
