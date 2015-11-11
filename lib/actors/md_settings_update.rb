require 'stringio'

module Evercam
  module Actors
    class MdSettingsUpdate < Mutations::Command
      required do
        string :id
      end

      optional do
        boolean :enabled
        string :week_days, :empty => true
        integer :alert_from_hour, :empty => true
        integer :alert_to_hour, :empty => true
        integer :alert_interval_min, :empty => true
        integer :sensitivity, :empty => true
        integer :x1, :empty => true
        integer :x2, :empty => true
        integer :y1, :empty => true
        integer :y2, :empty => true
      end

      def validate
        unless Camera.by_exid(id)
          add_error(:camera, :exists, 'Camera does not exist')
        end
      end

      def execute
        camera = ::Camera.by_exid(inputs[:id])

        [:enabled, :week_days, :alert_from_hour, :alert_to_hour, :alert_interval_min, :sensitivity,
          :x1, :x2, :y1, :y2].each do |resource|
          unless inputs[resource].nil?
            if camera.values[:config].has_key?('motion')
              camera.values[:config]['motion'].merge!(resource => inputs[resource]) if inputs[resource].present?
            else
              camera.values[:config].merge!('motion' => { resource => inputs[resource] }) if inputs[resource].present?
            end
          end
        end

        camera.save

        camera
      end
    end
  end
end
