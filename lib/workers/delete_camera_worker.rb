require_relative "../../app/api/v1/helpers/cache_helper.rb"

module Evercam
  class DeleteCameraWorker
    include Sidekiq::Worker
    include Evercam::CacheHelper

    def perform(exid)
      camera = ::Camera.by_exid(exid)
      raise NotFoundError, 'camera does not exist' unless camera

      CloudRecording.where(camera_id: camera.id).destroy
      SnapshotReport.where(camera_id: camera.id).destroy
      invalidate_for_camera(camera.exid)
      camera.destroy

      logger.info("Camera (#{exid}) deleted successfully.")
    rescue => e
      logger.warn "Camera delete exception: #{e.message}"
    end
  end
end
