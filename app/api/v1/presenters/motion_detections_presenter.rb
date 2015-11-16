require_relative './presenter'

module Evercam
  module Presenters
    class MotionDetection < Presenter

      root :motion_detections

      expose :frequency, documentation: {
        type: 'integer',
        desc: '',
        required: true
      }

      expose :minPosition, documentation: {
        type: 'integer',
        desc: 'Default minimal position to start pixels comparator is 0',
        required: true
      }

      expose :step, documentation: {
        type: 'integer',
        desc: 'Default step for pixels to compare is 2',
        required: true
      }


      expose :min, documentation: {
        type: 'integer',
        desc: 'Default Minimal difference between images is 30',
        required: true
      }

      expose :threshold, documentation: {
        type: 'integer',
        desc: 'Default Threshold is 5',
        required: true
      }


      expose :enabled, documentation: {
        type: 'boolean',
        desc: 'motion detection is enabled of the camera'
      }

      expose :alert_interval_min, documentation: {
        type: 'integer',
        desc: 'Motion detection alert interval minute.'
      }

      expose :sensitivity, documentation: {
        type: 'integer',
        desc: 'Motion Detection sensitivity.'
      }

      expose :x1, documentation: {
        type: 'integer',
        desc: 'Image selected area top left.'
      }

      expose :y1, documentation: {
        type: 'integer',
        desc: 'Image selected area bottom left.'
      }

      expose :x2, documentation: {
        type: 'integer',
        desc: 'Image selected area top right.'
      }

      expose :y2, documentation: {
        type: 'integer',
        desc: 'Image selected area bottom right.'
      }

      expose :alert_email, documentation: {
        type: "boolean",
        desc: "Send Motion detection notification"
      }

      expose :schedule, documentation: {
        type: 'array',
        desc: 'Motion detection notification schedule',
      }

      expose :emails, documentation: {
        type: 'array',
        desc: 'Motion detection notification schedule',
      }
    end
  end
end
