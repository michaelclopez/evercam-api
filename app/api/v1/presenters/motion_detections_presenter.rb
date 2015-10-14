require_relative './presenter'

module Evercam
  module Presenters
    class MotionDetection < Presenter

      root :motion_detections

      expose :frequency,
        documentation: {
        type: 'integer',
        desc: '',
        required: true
      }

      expose :minPosition,
        documentation: {
        type: 'integer',
        desc: 'Default is 0',
        required: true
      }

      expose :step,
        documentation: {
        type: 'integer',
        desc: 'Default is 2',
        required: true
      }


      expose :min,
        documentation: {
        type: 'integer',
        desc: 'Default is 30',
        required: true
      }

      expose :schedule,
        documentation: {
        type: 'array',
        desc: '',
        required: true
      }
    end
  end
end
