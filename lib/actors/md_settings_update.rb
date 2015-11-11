require 'stringio'

module Evercam
  module Actors
    class MdSettingsUpdate < Mutations::Command
      required do
        string :id
      end

      optional do
        boolean :enabled
        boolean :alert_email
        integer :alert_interval_min, :empty => true
        integer :sensitivity, :empty => true
        integer :x1, :empty => true
        integer :x2, :empty => true
        integer :y1, :empty => true
        integer :y2, :empty => true
        string :schedule
      end

      def validate
        unless Camera.by_exid(id)
          add_error(:camera, :exists, 'Camera does not exist')
        end

        unless inputs["schedule"].blank?
          begin
            JSON.parse(inputs["schedule"])
          rescue => _e
            add_error(:schedule, :invalid, "The parameter 'schedule' isn't formatted as a proper JSON.")
          end
        end
      end

      def execute
        camera = ::Camera.by_exid(inputs[:id])

        [:enabled, :alert_email, :alert_interval_min, :sensitivity, :x1, :x2, :y1, :y2].each do |resource|
          unless inputs[resource].nil?
            if camera.values[:config].has_key?('motion')
              camera.values[:config]['motion'].merge!(resource => inputs[resource]) if inputs[resource].present?
            else
              camera.values[:config].merge!('motion' => { resource => inputs[resource] }) if inputs[resource].present?
            end
          end
        end

        if inputs["schedule"].present?
          schedule = JSON.parse(inputs["schedule"])
          if camera.values[:config].has_key?('motion')
            camera.values[:config]['motion'].merge!("schedule" => schedule)
          else
            camera.values[:config].merge!('motion' => { "schedule" => schedule })
          end
        end

        camera.save

        camera
      end
    end
  end
end
