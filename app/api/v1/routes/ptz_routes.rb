module Evercam
  class V1PTZRoutes < Grape::API
    CAMERAS_URI = "#{Evercam::Config[:snapshots][:url]}v1/cameras"

    def self.ptz_get_endpoint(url, params)
      query = params.except(:id, :route_info).to_query
      url = "#{url}?#{query}"

      conn = Faraday.new(url: url) do |faraday|
        faraday.adapter Faraday.default_adapter
        faraday.options.timeout = 10
        faraday.options.open_timeout = 10
      end

      response = conn.get
      JSON.parse response.body
    end

    def self.ptz_post_endpoint(url, params)
      query = params.except(:id, :route_info).to_query
      url = "#{url}?#{query}"

      conn = Faraday.new(url: url) do |faraday|
        faraday.adapter Faraday.default_adapter
        faraday.options.timeout = 10
        faraday.options.open_timeout = 10
      end

      response = conn.post
      if response.body.to_s == "\"ok\""
        { status: "ok" }
      else
        JSON.parse response.body
      end
    end

    resource :cameras do
      #---------------------------------------------------------------------------
      # GET /v1/cameras/:id/ptz/status
      #---------------------------------------------------------------------------
      desc ''
      params do
        requires :id, type: String, desc: "Camera Id."
      end
      get '/:id/ptz/status' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

        url = "#{CAMERAS_URI}/#{camera[:exid]}/ptz/status"
        Evercam::V1PTZRoutes.ptz_get_endpoint(url, params)
      end

      #---------------------------------------------------------------------------
      # GET /v1/cameras/:id/ptz/presets
      #---------------------------------------------------------------------------
      desc ''
      params do
        requires :id, type: String, desc: "Camera Id."
      end
      get '/:id/ptz/presets' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

        url = "#{CAMERAS_URI}/#{camera[:exid]}/ptz/presets"
        Evercam::V1PTZRoutes.ptz_get_endpoint(url, params)
      end

      #---------------------------------------------------------------------------
      # POST /v1/cameras/:id/ptz/home
      #---------------------------------------------------------------------------
      desc ''
      params do
        requires :id, type: String, desc: "Camera Id."
      end
      post '/:id/ptz/home' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::EDIT)

        url = "#{CAMERAS_URI}/#{camera[:exid]}/ptz/home"
        Evercam::V1PTZRoutes.ptz_post_endpoint(url, params)
      end

      #---------------------------------------------------------------------------
      # POST /v1/cameras/:id/ptz/home/set
      #---------------------------------------------------------------------------
      desc ''
      params do
        requires :id, type: String, desc: "Camera Id."
      end
      post '/:id/ptz/home/set' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::EDIT)

        url = "#{CAMERAS_URI}/#{camera[:exid]}/ptz/home/set"
        Evercam::V1PTZRoutes.ptz_post_endpoint(url, params)
      end

      #---------------------------------------------------------------------------
      # POST /v1/cameras/:id/ptz/presets/:preset_token
      #---------------------------------------------------------------------------
      desc ''
      params do
        requires :id, type: String, desc: "Camera Id."
        requires :preset_token, type: String, desc: "Preset Token"
      end
      post '/:id/ptz/presets/:preset_token' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::EDIT)

        url = "#{CAMERAS_URI}/#{camera[:exid]}/ptz/presets/#{params[:preset_token]}"
        Evercam::V1PTZRoutes.ptz_post_endpoint(url, params)
      end

      #---------------------------------------------------------------------------
      # POST /v1/cameras/:id/ptz/presets/create/:preset_name
      #---------------------------------------------------------------------------
      desc ''
      params do
        requires :id, type: String, desc: "Camera Id."
        requires :preset_name, type: String, desc: "Preset Token"
      end
      post '/:id/ptz/presets/create/:preset_name' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::EDIT)

        url = "#{CAMERAS_URI}/#{camera[:exid]}/ptz/presets/create/#{params[:preset_name]}"
        Evercam::V1PTZRoutes.ptz_post_endpoint(url, params)
      end

      #---------------------------------------------------------------------------
      # POST /v1/cameras/:id/ptz/presets/go/:preset_token
      #---------------------------------------------------------------------------
      desc ''
      params do
        requires :id, type: String, desc: "Camera Id."
        requires :preset_token, type: String, desc: "Preset Token"
      end
      post '/:id/ptz/presets/go/:preset_token' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::EDIT)

        url = "#{CAMERAS_URI}/#{camera[:exid]}/ptz/presets/go/#{params[:preset_token]}"
        Evercam::V1PTZRoutes.ptz_post_endpoint(url, params)
      end

      #---------------------------------------------------------------------------
      # POST /v1/cameras/:id/ptz/continuous/start/:direction
      #---------------------------------------------------------------------------
      desc ''
      params do
        requires :id, type: String, desc: "Camera Id."
        requires :direction, type: String, desc: "Direction"
      end
      post '/:id/ptz/continuous/start/:direction' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::EDIT)

        url = "#{CAMERAS_URI}/#{camera[:exid]}/ptz/continuous/start/#{params[:direction]}"
        Evercam::V1PTZRoutes.ptz_post_endpoint(url, params)
      end

      #---------------------------------------------------------------------------
      # POST /v1/cameras/:id/ptz/continuous/zoom/:mode
      #---------------------------------------------------------------------------
      desc ''
      params do
        requires :id, type: String, desc: "Camera Id."
        requires :mode, type: String, desc: "Mode"
      end
      post '/:id/ptz/continuous/zoom/:mode' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::EDIT)

        url = "#{CAMERAS_URI}/#{camera[:exid]}/ptz/continuous/zoom/#{params[:mode]}"
        Evercam::V1PTZRoutes.ptz_post_endpoint(url, params)
      end

      #---------------------------------------------------------------------------
      # POST /v1/cameras/:id/ptz/continuous/stop
      #---------------------------------------------------------------------------
      desc ''
      params do
        requires :id, type: String, desc: "Camera Id."
      end
      post '/:id/ptz/continuous/stop' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::EDIT)

        url = "#{CAMERAS_URI}/#{camera[:exid]}/ptz/continuous/stop"
        Evercam::V1PTZRoutes.ptz_post_endpoint(url, params)
      end

      #---------------------------------------------------------------------------
      # POST /v1/cameras/:id/ptz/relative
      #---------------------------------------------------------------------------
      desc ''
      params do
        requires :id, type: String, desc: "Camera Id."
      end
      post '/:id/ptz/relative' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::EDIT)

        url = "#{CAMERAS_URI}/#{camera[:exid]}/ptz/relative"
        Evercam::V1PTZRoutes.ptz_post_endpoint(url, params)
      end

      #---------------------------------------------------------------------------
      # GET /v1/cameras/:id/macaddr
      #---------------------------------------------------------------------------
      desc ''
      params do
        requires :id, type: String, desc: "Camera Id."
      end
      get '/:id/macaddr' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

        url = "#{Evercam::Config[:snapshots][:url]}v1/cameras/#{camera[:exid]}/macaddr"
        Evercam::V1PTZRoutes.ptz_get_endpoint(url, params)
      end
    end
  end
end
