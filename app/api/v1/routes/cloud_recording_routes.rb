module Evercam
  class V1CloudRecordingRoutes < Grape::API

    resource :cameras do
      #---------------------------------------------------------------------------
      # GET /v1/cameras/:id/apps/cloud_recording
      #---------------------------------------------------------------------------
      desc '', {
        entity: Evercam::Presenters::CloudRecording
      }
      params do
        requires :id, type: String, desc: "Camera Id."
      end
      get '/:id/apps/cloud-recording' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

        cloud_recording = CloudRecording.where(camera_id: camera.id).first

        present Array(cloud_recording), with: Presenters::CloudRecording
      end

      #---------------------------------------------------------------------------
      # POST /v1/cameras/:id/apps/cloud_recording
      #---------------------------------------------------------------------------
      desc '', {
        entity: Evercam::Presenters::CloudRecording
      }
      params do
        requires :id, type: String, desc: "Camera Id."
        requires :frequency, type: Integer, desc: "Frequency of Snapshots per minute"
        requires :storage_duration, type: Integer, desc: "Storage Duration"
        requires :schedule, type: String, desc: "Schedule"
      end
      post '/:id/apps/cloud-recording' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

        outcome = Actors::CloudRecordingCreate.run(params)
        unless outcome.success?
          raise OutcomeError, outcome.to_json
        end
        present Array(outcome.result), with: Presenters::CloudRecording
      end

      #---------------------------------------------------------------------------
      # DELETE /v1/cameras/:id/apps/cloud_recording
      #---------------------------------------------------------------------------
      desc '', {
        entity: Evercam::Presenters::CloudRecording
      }
      params do
        requires :id, type: String, desc: "Camera Id."
      end
      delete '/:id/apps/cloud-recording' do
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

        cloud_recording = CloudRecording.where(camera_id: camera.id).first
        cloud_recording.delete

        {}
      end
    end
  end
end
