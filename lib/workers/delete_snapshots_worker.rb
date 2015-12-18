require_relative "../../app/api/v1/helpers/cache_helper.rb"

module Evercam
  class DeleteSnapshotsWorker
    include Sidekiq::Worker
    include Evercam::CacheHelper

    def perform(camera_exid, camera_id)
      begin
        Snapshot.where(:camera_id => camera_id).delete
        CameraActivity.where(camera_id: camera_id).delete
        Services::snapshot_bucket.objects.with_prefix("#{camera_exid}/snapshots/").delete_all

        logger.info("Camera (#{camera_exid}) snapshots, activities and s3 files deleted successfully.")
      rescue => e
        logger.warn "Camera delete exception: #{e.message}"
      end
    end
  end
end
