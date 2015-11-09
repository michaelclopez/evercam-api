require 'stringio'

module Evercam
  module Actors
    class MdSettingsUpdate < Mutations::Command

      required do
        string :id
        boolean :enabled
        integer :x1, :empty => true
        integer :x2, :empty => true
        integer :y1, :empty => true
        integer :y2, :empty => true
        integer :width, :empty => true
        integer :height, :empty => true
      end

      optional do
        string :week_days
        integer :alert_from_hour
        integer :alert_to_hour
        integer :alert_interval_min
        integer :sensitivity
      end

      def validate
        unless Camera.by_exid(id)
          add_error(:camera, :exists, 'Camera does not exist')
        end

        # if !vendor.blank? && Vendor.by_exid(vendor).first.nil?
        #   add_error(:vendor, :exists, 'Vendor does not exist')
        # end
      end

      def execute
        camera = ::Camera.by_exid(inputs[:id])

        [:external_http_port, :internal_http_port, :external_rtsp_port, :internal_rtsp_port].each do |port|
          unless inputs[port].nil?
            begin
              camera.values[:config].merge!({"#{port}" => inputs[port].empty? ? '' : Integer(inputs[port])})
            rescue ArgumentError
              add_error(port, :valid, "#{port} is invalid")
              return
            end
          end
        end

        [:enabled, :week_days, :alert_from_hour, :alert_to_hour, :alert_interval_min, :sensitivity,
        :x1, :x2, :y1, :y2, :width, :height].each do |resource|
          unless inputs[resource].nil?
            if camera.values[:config].has_key?('motion')
              camera.values[:config]['motion'].merge!({resource => inputs[resource]})
            else
              camera.values[:config].merge!({'motion' => { resource => inputs[resource]}})
            end
          end
        end

        camera.save

        camera
      end
    end
  end
end

