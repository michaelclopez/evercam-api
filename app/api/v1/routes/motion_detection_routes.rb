module Evercam
  class V1MotionDetectionRoutes < Grape::API
    resource :cameras do
      #---------------------------------------------------------------------------
      # GET /v1/cameras/:id/apps/motion_detection
      #---------------------------------------------------------------------------
      desc 'Return motion detection settings for specified camera',
        entity: Evercam::Presenters::MotionDetection
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
      desc 'Create motion detection settings for specified camera',
        entity: Evercam::Presenters::MotionDetection
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
      # PATCH /v1/cameras/:id/apps/motion_detection/settings
      #---------------------------------------------------------------------------
      desc 'Updates full or partial motion detection settings for specified camera',
           entity: Evercam::Presenters::Camera
      params do
        requires :id, type: String, desc: "Camera Id."
        optional :enabled, type: 'Boolean', desc: "Is camera motion detection enable or not"
        optional :alert_interval_min, type: Integer, desc: "Motion Detection alert interval"
        optional :sensitivity, type: Integer, desc: "Motion Detection sensitivity"
        optional :x1, type: Integer, desc: "Image selected area top left"
        optional :y1, type: Integer, desc: "Image selected area bottom left"
        optional :x2, type: Integer, desc: "Image selected area top right"
        optional :y2, type: Integer, desc: "Image selected area bottom left"
        optional :schedule, type: String, desc: "Schedule"
        optional :alert_email, type: 'Boolean', desc: "Is motion detection alert enable or not"
      end
      patch '/:id/apps/motion-detection/settings' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::EDIT)

        outcome = Actors::MdSettingsUpdate.run(params)
        unless outcome.success?
          raise OutcomeError, outcome.to_json
        end
        camera = ::Camera.by_exid!(params[:id])
        CacheInvalidationWorker.enqueue(camera.exid)
        CameraTouchWorker.perform_async(camera.exid)
        Evercam::Services.dalli_cache.set(params[:id], camera)
        present Array(outcome.result), with: Presenters::Camera
      end

      #---------------------------------------------------------------------------
      # POST /v1/cameras/:id/apps/motion_detection/email
      #---------------------------------------------------------------------------
      desc 'Add email to send motion detection alert for specified camera'
      params do
        requires :id, type: String, desc: "Camera Id."
        requires :email, type: String, desc: "Email where to send motion detection alert"
      end
      post '/:id/apps/motion-detection/email' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::EDIT)

        outcome = Actors::MotionDetectionEmailCreate.run(params)
        unless outcome.success?
          raise OutcomeError, outcome.to_json
        end
        camera = ::Camera.by_exid!(params[:id])
        CacheInvalidationWorker.enqueue(camera.exid)
        CameraTouchWorker.perform_async(camera.exid)
        Evercam::Services.dalli_cache.set(params[:id], camera)
        { email: params[:email] }
      end

      #---------------------------------------------------------------------------
      # DELETE /v1/cameras/:id/apps/motion_detection/email
      #---------------------------------------------------------------------------
      desc 'Delete motion detection alert email'
      params do
        requires :id, type: String, desc: "Camera Id."
        requires :email, type: String, desc: "Email where to send motion detection alert"
      end
      delete '/:id/apps/motion-detection/email' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::EDIT)

        outcome = Actors::MotionDetectionEmailDelete.run(params)
        unless outcome.success?
          raise OutcomeError, outcome.to_json
        end
        camera = ::Camera.by_exid!(params[:id])
        CacheInvalidationWorker.enqueue(camera.exid)
        CameraTouchWorker.perform_async(camera.exid)
        Evercam::Services.dalli_cache.set(params[:id], camera)
        {}
      end

      #---------------------------------------------------------------------------
      # DELETE /v1/cameras/:id/apps/motion_detection
      #---------------------------------------------------------------------------
      desc 'Delete motion detection settings for specified camera',
        entity: Evercam::Presenters::MotionDetection
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
