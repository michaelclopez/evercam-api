module Evercam
  class V1MotionDetectionRoutes < Grape::API

    resource :cameras do
      #---------------------------------------------------------------------------
      # GET /v1/cameras/:id/apps/motion_detection
      #---------------------------------------------------------------------------
      desc '', {
        entity: Evercam::Presenters::MotionDetection
      }
      params do
        requires :id, type: String, desc: "Camera Id."
      end
      get '/:id/apps/motion-detection' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

        motion_detection = MotionDetection.where(camera_id: camera.id).first

        present Array(motion_detection), with: Presenters::MotionDetection
      end

      #---------------------------------------------------------------------------
      # POST /v1/cameras/:id/apps/motion_detection
      #---------------------------------------------------------------------------
      desc '', {
        entity: Evercam::Presenters::MotionDetection
      }
      params do
        requires :id, type: String, desc: "Camera Id."
        requires :frequency, type: Integer, desc: "Frequency of Snapshots per minute"
        requires :minPosition, type: Integer, desc: "Minimal Position of where to start in pixels"
        requires :step, type: Integer, desc: "Check each `step` pixel"
        requires :min, type: Integer, desc: "Change between previous and current image should be at least `min` rate"
        requires :threshold, type: Integer, desc: "Motion Detection threshold to fire the motino even or notification"
        requires :schedule, type: String, desc: "Schedule"
      end
      post '/:id/apps/motion-detection' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

        outcome = Actors::MotionDetectionCreate.run(params)
        unless outcome.success?
          raise OutcomeError, outcome.to_json
        end
        present Array(outcome.result), with: Presenters::MotionDetection
      end

      #---------------------------------------------------------------------------
      # DELETE /v1/cameras/:id/apps/motion_detection
      #---------------------------------------------------------------------------
      desc '', {
        entity: Evercam::Presenters::MotionDetection
      }
      params do
        requires :id, type: String, desc: "Camera Id."
      end
      delete '/:id/apps/motion-detection' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

        motion_detection = MotionDetection.where(camera_id: camera.id).first
        motion_detection.delete

        {}
      end
    end
  end
end
