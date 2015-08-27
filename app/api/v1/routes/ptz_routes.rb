module Evercam
  class V1PTZRoutes < Grape::API
    CAMERAS_URI = "#{Evercam::Config[:snapshots][:url]}v1/cameras"

    def self.ptz_get_endpoint(url)
      conn = Faraday.new(url: url) do |faraday|
        faraday.adapter Faraday.default_adapter
        faraday.options.timeout = 10
        faraday.options.open_timeout = 10
      end

      response = conn.get
      JSON.parse response.body
    end

    #---------------------------------------------------------------------------
    # GET /v1/cameras/:id/ptz/status
    #---------------------------------------------------------------------------
    desc ''
    params do
      requires :id, type: String, desc: "Camera Id."
    end
    get '/cameras/:id/ptz/status' do
      camera = get_cam(params[:id])
      rights = requester_rights_for(camera)
      raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

      url = "#{CAMERAS_URI}/#{camera[:exid]}/ptz/status"
      Evercam::V1PTZRoutes.ptz_get_endpoint(url)
    end

    #---------------------------------------------------------------------------
    # GET /v1/cameras/:id/ptz/presets
    #---------------------------------------------------------------------------
    desc ''
    params do
      requires :id, type: String, desc: "Camera Id."
    end
    get '/cameras/:id/ptz/presets' do
      camera = get_cam(params[:id])
      rights = requester_rights_for(camera)
      raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

      url = "#{CAMERAS_URI}/#{camera[:exid]}/ptz/presets"
      Evercam::V1PTZRoutes.ptz_get_endpoint(url)
    end
  end
end
