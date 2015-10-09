require_relative '../../lib/services'

module Evercam
  class CameraTouchWorker
    include Sidekiq::Worker

    sidekiq_options queue: :status

    def perform(camera_id)
      cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
      cipher.encrypt
      cipher.key = "#{Evercam::Config[:snapshots][:key]}"
      cipher.iv = "#{Evercam::Config[:snapshots][:iv]}"
      cipher.padding = 0

      message = "|||"
      message << ' ' until message.length % 16 == 0
      token = cipher.update(message)
      token << cipher.final

      url = "#{Evercam::Config[:snapshots][:url]}v1/cameras/#{camera_id}/touch?token=#{Base64.urlsafe_encode64(token)}"

      conn = Faraday.new(url: url) do |faraday|
        faraday.adapter Faraday.default_adapter
        faraday.options.timeout = 10
        faraday.options.open_timeout = 10
      end

      conn.get

      logger.info("Camera updated signal sent to evercam-media for camera '#{camera_id}'.")
    end
  end
end
