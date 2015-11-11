require_relative '../../lib/services'
require_relative '../../app/api/v1/helpers/cache_helper'

module Evercam
  class CacheInvalidationWorker
    include Evercam::CacheHelper
    include Sidekiq::Worker

    sidekiq_options queue: :cache

    def self.enqueue(camera_exid)
      CacheInvalidationWorker.perform_async(camera_exid)
    end

    def perform(camera_exid)
      invalidate_for_camera(camera_exid)
      logger.info("Invalidated cache for camera #{camera_exid}")
    end
  end
end
