require 'aws-sdk'
require 'sidekiq'
require 'sidekiq/api'
require 'evercam_misc'
require 'dalli'

Sidekiq.configure_server do |c|
  c.redis = Evercam::Config[:redis]
end

Sidekiq.configure_client do |c|
  c.redis = Evercam::Config[:redis]
end

require_relative "workers/intercom_events_worker"
require_relative "workers/cache_invalidation_worker"
require_relative "workers/email_worker"
require_relative "workers/camera_touch_worker"
require_relative "workers/delete_camera_worker"
require_relative "workers/delete_user_worker"
require_relative "workers/delete_snapshots_worker"
