require_relative '../presenters/camera_presenter'
require_relative '../presenters/camera_share_presenter'
require_relative '../helpers/cache_helper.rb'
require 'faraday/digestauth'
require 'typhoeus/adapters/faraday'

require 'uri'

module Evercam
  class V1CameraRoutes < Grape::API

    TIMEOUT = 5

    include WebErrors
    include Evercam::CacheHelper

    resource :cameras do

      #---------------------------------------------------------------------------
      # POST /v1/cameras/test
      #---------------------------------------------------------------------------
      desc 'Tests if given camera parameters are correct'
      params do
        requires :external_url, type: String, desc: "External camera url."
        requires :jpg_url, type: String, desc: "Snapshot url."
        optional :cam_username, type: String, desc: "Camera username."
        optional :cam_password, type: String, desc: "Camera password."
        optional :vendor_id, type: String, desc: "Vendor Id"
      end
      post '/test' do
        require 'openssl'
        require 'base64'

        vendor_exid = params[:vendor_id]
        cam_auth = "#{params[:cam_username]}:#{params[:cam_password]}"

        api_id = params.fetch('api_id', '')
        api_key = params.fetch('api_key', '')
        credentials = "#{api_id}:#{api_key}"

        cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
        cipher.encrypt
        cipher.key = "#{Evercam::Config[:snapshots][:key]}"
        cipher.iv = "#{Evercam::Config[:snapshots][:iv]}"
        cipher.padding = 0

        message = params[:external_url]
        message << "/#{params[:jpg_url].gsub('X_QQ_X', '?').gsub('X_AA_X', '&')}"
        message << "|#{cam_auth}|#{credentials}|#{Time.now.utc.iso8601}|"
        message << ' ' until message.length % 16 == 0
        token = cipher.update(message)
        token << cipher.final

        url = "#{Evercam::Config[:snapshots][:url]}v1/cameras/test?token=#{Base64.urlsafe_encode64(token)}&vendor_exid=#{vendor_exid}"

        conn = Faraday.new(url: url) do |faraday|
          faraday.adapter Faraday.default_adapter
          faraday.options.timeout = 10
          faraday.options.open_timeout = 10
        end

        response = conn.post
        status response.status
        JSON.parse response.body
      end

      #---------------------------------------------------------------------------
      # GET /v1/cameras/:id
      #---------------------------------------------------------------------------
      desc 'Returns all data for a given camera', {
        entity: Evercam::Presenters::Camera
      }
      params do
        requires :id, type: String, desc: "Camera Id."
      end
      get '/:id' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        unless rights.allow?(AccessRight::LIST)
          raise AuthorizationError.new if camera.is_public?
          if !rights.allow?(AccessRight::VIEW) && !camera.is_public?
            raise NotFoundError.new
          end
        end

        CameraActivity.create(
          camera_id: camera.id,
          camera_exid: camera.exid,
          access_token_id: (access_token.nil? ? nil : access_token.id),
          name: (access_token.nil? ? nil : User.where(id: access_token.user_id).first.fullname unless access_token.nil?),
          action: 'accessed',
          done_at: Time.now,
          ip: request.ip
        )

        options = {
          minimal: !rights.allow?(AccessRight::VIEW),
          with: Presenters::Camera
        }
        options[:user] = rights.requester unless rights.requester.nil?
        present([camera], options)
      end

      before do
        authorize!
      end

      #---------------------------------------------------------------------------
      # GET /v1/cameras
      #---------------------------------------------------------------------------
      desc "Returns data for a specified set of cameras.", {
        entity: Evercam::Presenters::Camera
      }
      params do
        optional :ids, type: String, desc: "Comma separated list of camera identifiers for the cameras being queried."
        optional :user_id, type: String, desc: "The Evercam user name or email address for the new camera owner."
        optional :exclude_shared, type: 'Boolean', desc: "Set to true to exclude cameras shared with the user in the fetch."
      end
      get do
        include_shared = true
        include_shared = false if params.include?(:exclude_shared) && params[:exclude_shared]
        include_shared = false if params.include?(:include_shared) && params[:include_shared] == "false"

        requested_by_client = caller.kind_of?(Client)
        if params.include?(:ids) && params[:ids]
          cameras = []
          ids = params[:ids].split(",").inject([]) { |list, entry| list << entry.strip }
          Camera.where(exid: ids).each do |camera|
            rights = requester_rights_for(camera)
            rights = CameraRightSet.new(camera, rights.token.grantor) if rights.type == :client
            if rights.allow_any?(AccessRight::LIST, AccessRight::VIEW)
              presenter = Evercam::Presenters::Camera.new(camera)
              cameras << presenter.as_json(minimal: !rights.allow?(AccessRight::VIEW))
            end
          end
        else
          if params.include?(:user_id) && params[:user_id]
            user = ::User.by_login(params[:user_id])
            if user.nil?
              raise_error(404, "user_not_found",
                "Unable to locate the '#{params[:user_id]}' user.",
                params[:user_id])
            end
          else
            user = ::User.where(api_id: params[:api_id], api_key: params[:api_key]).first
          end

          key = "cameras|#{user.username}|#{include_shared}"
          cameras = Evercam::Services.dalli_cache.get(key) unless requested_by_client

          if cameras.blank?
            cameras = []
            query = Camera.where(owner: user)
            if include_shared
              query = query.association_left_join(:shares)
                        .or(Sequel.qualify(:shares, :user_id) => user.id)
              query = query.group(Sequel.qualify(:cameras, :id))
              query = query.select(
                Sequel.qualify(:cameras, :id),
                Sequel.qualify(:cameras, :created_at),
                Sequel.qualify(:cameras, :updated_at),
                :exid,
                :owner_id, :is_public, :config,
                :name, :last_polled_at, :is_online,
                :timezone, :last_online_at, :location,
                :mac_address, :model_id, :discoverable, :preview, :thumbnail_url
              )
            end

            unless requested_by_client
              tokens = AccessToken.where(user_id: user.id).all
            end

            query.order(:name).eager(:owner, :vendor_model => :vendor).all.select do |camera|
              rights = requester_rights_for(camera)
              rights = CameraRightSet.new(camera, rights.token.grantor) if rights.type == :client
              if rights.allow_any?(AccessRight::LIST, AccessRight::VIEW)
                presenter = Evercam::Presenters::Camera.new(camera)
                cameras << presenter.as_json(
                  minimal: !rights.allow?(AccessRight::VIEW),
                  user: caller,
                  tokens: tokens
                )
              end
            end
            Evercam::Services.dalli_cache.set(key, cameras) unless requested_by_client
          end
        end
        {cameras: cameras}
      end

      #-------------------------------------------------------------------------
      # POST /v1/cameras
      #-------------------------------------------------------------------------
      desc 'Creates a new camera owned by the authenticating user', {
        entity: Evercam::Presenters::Camera
      }
      params do
        optional :id, type: String, desc: "Camera Id."
        requires :name, type: String, desc: "Camera name."
        optional :vendor, type: String, desc: "Camera vendor id."
        optional :model, type: String, desc: "Camera model id."
        optional :timezone, type: String, desc: "Camera timezone."
        requires :is_public, type: 'Boolean', desc: "Is camera public?"
        optional :is_online, type: 'Boolean', desc: "Is camera online? (If you leave it empty it will be automatically checked)"
        optional :discoverable, type: 'Boolean', desc: "Is camera discoverable in our piblic cameras page?"
        optional :cam_username, type: String, desc: "Camera username."
        optional :cam_password, type: String, desc: "Camera password."
        optional :mac_address, type: String, desc: "Camera MAC address."
        optional :location_lat, type: Float, desc: "Camera GPS latitude location."
        optional :location_lng, type: Float, desc: "Camera GPS longitude location."
        optional :external_host, type: String, desc: "External camera host."
        optional :internal_host, type: String, desc: "Internal camera host."
        optional :external_http_port, type: String, desc: "External camera http port."
        optional :internal_http_port, type: String, desc: "Internal camera http port."
        optional :external_rtsp_port, type: String, desc: "External camera rtsp port."
        optional :internal_rtsp_port, type: String, desc: "Internal camera rtsp port."
        optional :jpg_url, type: String, desc: "Snapshot url."
        optional :mjpg_url, type: String, desc: "Mjpg url."
        optional :mpeg_url, type: String, desc: "MPEG url."
        optional :audio_url, type: String, desc: "Audio url."
        optional :h264_url, type: String, desc: "H264 url."
      end
      post do
        raise BadRequestError.new("Requester is not a user.") if caller.nil? || !caller.instance_of?(User)
        if params[:id].blank?
          parameters = {}.merge(params).merge(username: caller.username, id: auto_generate_camera_id(params[:name]))
        else
          parameters = {}.merge(params).merge(username: caller.username)
        end
        outcome    = Actors::CameraCreate.run(parameters)
        unless outcome.success?
          IntercomEventsWorker.perform_async('failed-creating-camera', caller.email)
          raise OutcomeError, outcome.to_json
        end
        invalidate_for_user(caller.username)
        IntercomEventsWorker.perform_async('created-camera', caller.email)
        CameraTouchWorker.perform_async(params[:id])
        present Array(outcome.result), options, with: Presenters::Camera, user: caller
      end

      #-------------------------------------------------------------------------
      # PATCH /v1/cameras/:id
      #-------------------------------------------------------------------------
      desc 'Updates full or partial data for an existing camera', {
        entity: Evercam::Presenters::Camera
      }
      params do
        requires :id, type: String, desc: "Camera Id."
        optional :name, type: String, desc: "Camera name."
        optional :vendor, type: String, desc: "Camera vendor id."
        optional :model, type: String, desc: "Camera model name."
        optional :timezone, type: String, desc: "Camera timezone."
        optional :is_public, type: 'Boolean', desc: "Is camera public?"
        optional :is_online, type: 'Boolean', desc: "Is camera online? (If you leave it empty it will be automatically checked)"
        optional :discoverable, type: 'Boolean', desc: "Is camera discoverable in our piblic cameras page?"
        optional :cam_username, type: String, desc: "Camera username."
        optional :cam_password, type: String, desc: "Camera password."
        optional :mac_address, type: String, desc: "Camera MAC address."
        optional :location_lat, type: 'Float', desc: "Camera GPS latitude location."
        optional :location_lng, type: 'Float', desc: "Camera GPS longitude location."
        optional :external_host, type: String, desc: "External camera host."
        optional :internal_host, type: String, desc: "Internal camera host."
        optional :external_http_port, type: String, desc: "External camera http port."
        optional :internal_http_port, type: String, desc: "Internal camera http port."
        optional :external_rtsp_port, type: String, desc: "External camera rtsp port."
        optional :internal_rtsp_port, type: String, desc: "Internal camera rtsp port."
        optional :jpg_url, type: String, desc: "Snapshot url."
        optional :mjpg_url, type: String, desc: "Mjpg url."
        optional :mpeg_url, type: String, desc: "MPEG url."
        optional :audio_url, type: String, desc: "Audio url."
        optional :h264_url, type: String, desc: "H264 url."
      end
      patch '/:id' do
        camera = Evercam::Services.dalli_cache.get(params[:id])
        camera = ::Camera.by_exid!(params[:id]) if camera.nil?
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::EDIT)

        Camera.db.transaction do
          outcome = Actors::CameraUpdate.run(params)
          unless outcome.success?
            raise OutcomeError, outcome.to_json
          end

          CameraActivity.create(
            camera_id: camera.id,
            camera_exid: camera.exid,
            access_token_id: (access_token.nil? ? nil : access_token.id),
            name: (access_token.nil? ? nil : User.where(id: access_token.user_id).first.fullname unless access_token.nil?),
            action: 'edited',
            done_at: Time.now,
            ip: request.ip
          )
        end
        if params[:is_public] and not caller.kind_of?(Client)
          IntercomEventsWorker.perform_async('made-camera-public', caller.email)
        end

        camera = ::Camera.by_exid!(params[:id])

        CacheInvalidationWorker.enqueue(camera.exid)
        CameraTouchWorker.perform_async(camera.exid)
        Evercam::Services.dalli_cache.set(params[:id], camera)
        present Array(camera), with: Presenters::Camera, user: caller
      end

      #-------------------------------------------------------------------------
      # DELETE /v1/cameras/:id
      #-------------------------------------------------------------------------
      desc 'Deletes a camera from Evercam along with any stored media', {
        entity: Evercam::Presenters::Camera
      }
      delete '/:id' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::DELETE)

        original_owner = camera.owner
        camera.owner = User.by_login("admin@evercam.io")
        camera.discoverable = false
        camera.is_public = false
        camera.save
        invalidate_for_camera(camera.exid)
        invalidate_for_user(original_owner.username)
        CloudRecording.where(camera: camera).each(&:delete)
        MotionDetection.where(camera: camera).each(&:delete)

        DeleteCameraWorker.perform_async(camera.exid)
        {}
      end

      #-------------------------------------------------------------------------
      # PUT /v1/cameras/:id
      #-------------------------------------------------------------------------
      desc 'Transfers the ownership of a camera from one user to another', {
        entity: Evercam::Presenters::Camera
      }
      params do
         requires :id, type: String, desc: "The unique identifier for the camera."
         requires :user_id, type: String, desc: "The Evercam user name or email address for the new camera owner."
      end
      put '/:id' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.is_owner?

        new_owner = User.by_login(params[:user_id])
        raise NotFoundError.new("Specified user does not exist.") if new_owner.nil?
        old_owner = camera.owner.username
        CacheInvalidationWorker.enqueue(camera.exid)
        CameraTouchWorker.perform_async(camera.exid)
        Actors::ShareDelete.run({ id: camera.id, user_id: new_owner.id, ip: request.ip })
        rights = generate_rights_list("full")
        rights = rights.is_a?(String) ? rights : rights.join(",")
        camera.update(owner: new_owner)
        Actors::ShareCreate.run({ id: camera.exid, email: old_owner, rights: rights, grantor: new_owner.username })
        Evercam::Services.dalli_cache.set(params[:id], camera)
        present Array(camera), with: Presenters::Camera, user: caller
      end
    end
  end
end
