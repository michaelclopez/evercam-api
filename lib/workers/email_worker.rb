require 'net/http'
require 'faraday'
require 'faraday/digestauth'
require 'socket'
require_relative '../actors/mailers/user_mailer'

module Evercam
  class EmailWorker

    include Sidekiq::Worker
    sidekiq_options retry: false

    TIMEOUT = 5

    def perform(params)
      camera = Camera.by_exid(params['camera'])
      user = User.by_login(params['user']) if params['user']
      response = nil
      add_snap = false
      snap = nil

      # Get image if needed
      if ['share_request', 'share', 'clip-completed', 'clip-failed'].include?(params['type']) && !camera.nil? && !camera.external_url.nil?
        begin
          conn = Faraday.new(:url => camera.external_url) do |faraday|
            faraday.request :basic_auth, camera.cam_username, camera.cam_password
            faraday.request :digest, camera.cam_username, camera.cam_password
            faraday.adapter Faraday.default_adapter  # make requests with Net::HTTP, because curl crashes on Heroku
            faraday.options.timeout = 10           # open/read timeout in seconds
            faraday.options.open_timeout = 10      # connection open timeout in seconds
          end
          response = conn.get do |req|
            req.url camera.res_url('jpg')
          end
          if response.status == 200
            unless response.headers.fetch('content-type', '').start_with?('image')
              logger.warn("Camera seems online, but returned content type: #{response.headers.fetch('Content-Type', '')}")
            end
          end
        rescue URI::InvalidURIError
          raise BadRequestError, 'Invalid URL'
        rescue Net::OpenTimeout
          # offline
        rescue Faraday::TimeoutError
          # offline
        rescue Faraday::ConnectionFailed
          # offline
        rescue => e
          # we weren't expecting this (famous last words)
          logger.error(e.message)
          logger.error(e.class)
          logger.error(e.backtrace.inspect)
        end

      end

      unless response.nil?
        add_snap = true
        snap = response.body
      end

      if params['type'] == 'share_request'
        Mailers::UserMailer.share_request(user: user, email: params['email'], message: params['message'], camera: camera,
                                        attachments: {'snapshot.jpg' => snap}, key: params['key'],
                                        add_snap: add_snap, socket: Socket.gethostname)
      elsif params['type'] == 'share'
        Mailers::UserMailer.share(user: user, email: params['email'], message: params['message'], camera: camera,
                                  attachments: {'snapshot.jpg' => snap}, add_snap: add_snap,
                                  socket: Socket.gethostname)
      elsif params['type'] == 'clip-completed'
        Mailers::UserMailer.create_success(archive: archive, attachments: {'snapshot.jpg' => snap}, add_snap: add_snap,
                                           socket: Socket.gethostname)
      elsif params['type'] == 'clip-failed'
        Mailers::UserMailer.create_fail(archive: archive, attachments: {'snapshot.jpg' => snap}, add_snap: add_snap,
                                        socket: Socket.gethostname)
      end
    end

  end
end

