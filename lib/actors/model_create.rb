module Evercam
  module Actors
    class ModelCreate < Mutations::Command

      required do
        string :id
        string :name
        string :vendor_id
        string :jpg_url
        string :mjpg_url
        string :h264_url
      end

      optional do
        string :mobile_url
        string :mpeg4_url
        string :lowres_url
        string :default_username
        string :default_password
        string :shape
        string :resolution
        string :official_url
        string :audio_url
        string :more_info
        boolean :poe
        boolean :wifi
        boolean :upnp
        boolean :ptz
        boolean :infrared
        boolean :varifocal
        boolean :sd_card
        boolean :audio_io
        boolean :onvif
        boolean :psia
        boolean :discontinued
      end

      def validate
        unless id =~ /^[a-z0-9\-_]+$/ and id.length > 3
          add_error(:id, :valid, 'Model ID can only contain lower case letters, numbers, hyphens and underscore. Minimum length is 4.')
        end
      end

      def execute

        vendor = Vendor.where(exid: inputs[:vendor_id]).first
        raise NotFoundError.new("Unable to locate a vendor for '#{inputs[:vendor_id]}'.",
                                "vendor_not_found_error", inputs[:vendor_id]) if vendor.blank?
        model = VendorModel.new(
            exid: id,
            name: name,
            vendor: vendor,
            jpg_url: jpg_url,
            h264_url: h264_url,
            mjpg_url: mjpg_url,
            config: {}
        )
        [:jpg, :mjpg, :mpeg4, :mobile, :h264, :lowres].each do |resource|
          url_name = "#{resource}_url"
          unless inputs[url_name].blank?
            if model.values[:config].has_key?('snapshots')
              model.values[:config]['snapshots'].merge!({resource => inputs[url_name]})
            else
              model.values[:config].merge!({'snapshots' => { resource => inputs[url_name]}})
            end
          end
        end
        model.shape = shape if shape
        model.resolution = resolution if resolution
        model.official_url = official_url if official_url
        model.audio_url = audio_url if audio_url
        model.more_info = more_info if more_info
        model.poe = poe if poe
        model.wifi = wifi if wifi
        model.upnp = upnp if upnp
        model.ptz = ptz if ptz
        model.infrared = infrared if infrared
        model.varifocal = varifocal if varifocal
        model.sd_card = sd_card if sd_card
        model.audio_io = audio_io if audio_io
        model.onvif = onvif if onvif
        model.psia = psia if psia
        model.discontinued = discontinued if discontinued

        if inputs[:default_username] or inputs[:default_password]
          model.values[:config].merge!({'auth' => {'basic' => {'username' => inputs[:default_username], 'password' => inputs[:default_password] }}})
        end

        VendorModel.db.transaction do
          model.save
        end
      end
    end
  end
end
