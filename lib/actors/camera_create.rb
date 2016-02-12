module Evercam
  module Actors
    class CameraCreate < Mutations::Command

      required do
        string :id
        string :name
        string :username
        boolean :is_public
        string :external_host
      end

      optional do
        string :timezone
        string :mac_address
        string :model
        string :vendor

        string :jpg_url
        string :mjpg_url
        string :h264_url
        string :audio_url
        string :mpeg_url
        string :internal_host
        integer :external_http_port
        integer :internal_http_port
        integer :external_rtsp_port
        integer :internal_rtsp_port

        string :cam_username
        string :cam_password

        float :location_lng
        float :location_lat

        boolean :is_online
        boolean :discoverable
        boolean :is_online_email_owner_notification
      end

      def validate
        unless id =~ /^[a-z0-9\-_]+$/ and id.length > 3
          add_error(:id, :valid, 'Camera ID can only contain lower case letters, numbers, hyphens and underscore. Minimum length is 4.')
        end

        if name.length > 25
          add_error(:name, :valid, 'Camera Name is too long. Maximum 24 characters.')
        end

        if !(external_host =~ Evercam::VALID_IP_ADDRESS_REGEX or external_host =~ Evercam::VALID_HOSTNAME_REGEX)
          add_error(:external_host, :valid, 'External url is invalid')
        end

        if internal_host && !internal_host.blank? && !(internal_host =~ Evercam::VALID_IP_ADDRESS_REGEX or internal_host =~ Evercam::VALID_HOSTNAME_REGEX)
          add_error(:internal_host, :valid, 'Internal url is invalid')
        end

        if timezone && false == Timezone::Zone.names.include?(timezone)
          add_error(:timezone, :valid, 'Timezone does not exist or is invalid')
        end

        if model && vendor.blank?
          add_error(:model, :valid, 'If you provide model you must also provide vendor')
        end

        if mac_address && !(mac_address =~ /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/)
          add_error(:mac_address, :valid, 'Mac address is invalid')
        end

        if location_lng && nil == location_lat
          add_error(:location_lat, :valid, 'Must provide both location coordinates')
        end

        if location_lat && nil == location_lng
          add_error(:location_lng, :valid, 'Must provide both location coordinates')
        end
      end

      def execute
        user = User.by_login(inputs[:username])
        raise NotFoundError.new("Unable to locate a user for '#{inputs[:username]}'.",
                                "user_not_found_error", inputs[:username]) if user.nil?

        vendor = model = nil
        if inputs[:vendor]
          vendor = Vendor.where(exid: inputs[:vendor].downcase).first
          raise Evercam::NotFoundError.new("Unable to locate a vendor for '#{inputs[:vendor]}'.",
                                           "vendor_not_found_error", inputs[:vendor]) if vendor.nil?
        end

        if inputs[:model]
          model = VendorModel.where(exid: inputs[:model], vendor: vendor).first
          raise Evercam::NotFoundError.new("Unable to locate a model for '#{inputs[:model]}' under the '#{vendor.name}' vendor.",
                                           "model_not_found_error", inputs[:model]) if model.nil?
        elsif !vendor.nil?
          model = VendorModel.where(name: VendorModel::DEFAULT, vendor: vendor).first
          raise Evercam::NotFoundError.new("Unable to locate a default model for the '#{vendor.name}' vendor.",
                                           "model_not_found_error", inputs[:model]) if model.nil?
        end

        if Camera.where(exid: inputs[:id]).count != 0
          raise Evercam::ConflictError.new("A camera with the id '#{inputs[:id]}' already exists.",
                                           "duplicate_camera_id_error", inputs[:id])
        end

        if inputs[:internal_host].blank? && inputs[:external_host].blank?
          raise Evercam::BadRequestError.new("You must specify internal and/or external host.",
                                             "incomplete_camera_urls_error")
        end

        camera = Camera.new(exid: id,
                            name: name,
                            owner: user,
                            is_public: is_public,
                            config: {})
        camera.vendor_model = model unless model.nil?

        [:jpg, :mjpg, :h264, :audio, :mpeg].each do |resource|
          url_name = "#{resource}_url"
          unless inputs[url_name].nil?
            unless inputs[url_name].empty?
              inputs[url_name].prepend('/') if inputs[url_name][0,1] != '/'
            end
            if camera.values[:config].has_key?('snapshots')
              camera.values[:config]['snapshots'].merge!({resource => inputs[url_name]})
            else
              camera.values[:config].merge!({'snapshots' => { resource => inputs[url_name]}})
            end
          end
        end

        if inputs[:cam_username] or inputs[:cam_password]
          camera.values[:config].merge!({'auth' => {'basic' => {'username' => inputs[:cam_username], 'password' => inputs[:cam_password] }}})
        end

        # setup camera GPS location
        if location_lng && location_lat
          camera.location = { lng: location_lng, lat: location_lat }
        end

        camera.timezone    = timezone if timezone
        camera.mac_address = mac_address if mac_address

        camera.discoverable = inputs[:discoverable] if inputs[:discoverable]
        camera.is_online_email_owner_notification = inputs[:is_online_email_owner_notification] if inputs[:is_online_email_owner_notification]
        if inputs[:is_online] && inputs[:is_online].present?
          camera.is_online = inputs[:is_online]
          camera.last_online_at = Time.now
        else
          camera.is_online = true
          camera.last_online_at = Time.now
        end

        camera.values[:config].merge!({'external_host' => inputs[:external_host]}) if inputs[:external_host]
        camera.values[:config].merge!({'external_http_port' => inputs[:external_http_port]}) if inputs[:external_http_port]
        camera.values[:config].merge!({'external_rtsp_port' => inputs[:external_rtsp_port]}) if inputs[:external_rtsp_port]

        camera.values[:config].merge!({'internal_host' => inputs[:internal_host]}) if inputs[:internal_host]
        camera.values[:config].merge!({'internal_http_port' => inputs[:internal_http_port]}) if inputs[:internal_http_port]
        camera.values[:config].merge!({'internal_rtsp_port' => inputs[:internal_rtsp_port]}) if inputs[:internal_rtsp_port]
        camera.save

        CameraActivity.create(camera_id: camera.id,
                              camera_exid: camera.exid,
                              access_token_id: user.token.id,
                              name: user.fullname,
                              action: 'created',
                              done_at: Time.now)

        camera
      end
    end
  end
end
