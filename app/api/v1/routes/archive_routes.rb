require_relative '../presenters/archive_presenter'

module Evercam
  class V1ArchiveRoutes < Grape::API
    include WebErrors

    resource :cameras do
      before do
        authorize!
      end

      #-------------------------------------------------------------------------
      # GET /v1/cameras/:id/archives
      #-------------------------------------------------------------------------
      desc 'Returns available archives for the camera',{
        entity: Evercam::Presenters::Archive
      }
      params do
        requires :id, type: String, desc: 'The unique identifier for the camera.'
      end
      get '/:id/archives' do
        params[:id].downcase!
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        unless rights.allow?(AccessRight::LIST)
          raise AuthorizationError.new if camera.is_public?
          if !rights.allow?(AccessRight::VIEW) && !camera.is_public?
            raise NotFoundError.new
          end
        end
        archives = Archive.where(camera_id: camera.id)
        present Array(archives), with: Presenters::Archive
      end

      #-------------------------------------------------------------------------
      # GET /v1/cameras/:id/archives/:archive_id
      #-------------------------------------------------------------------------
      desc 'Returns all data for a given archive',{
        entity: Evercam::Presenters::Archive
      }
      params do
        requires :id, type: String, desc: 'The unique identifier for the camera.'
        requires :archive_id, type: String, desc: 'The unique identifier for the archive.'
      end
      get '/:id/archives/:archive_id' do
        params[:id].downcase!
        params[:archive_id].downcase!
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        unless rights.allow?(AccessRight::LIST)
          raise AuthorizationError.new if camera.is_public?
          if !rights.allow?(AccessRight::VIEW) && !camera.is_public?
            raise NotFoundError.new
          end
        end
        archive = Archive.where(exid: params[:archive_id])
        raise NotFoundError.new("The '#{params[:archive_id]}' archive does not exist.") if archive.count == 0
        present Array(archive), with: Presenters::Archive
      end

      #-------------------------------------------------------------------------
      # POST /v1/cameras/:id/archives
      #-------------------------------------------------------------------------
      desc 'Create a new archive',{
        entity: Evercam::Presenters::Archive
      }
      params do
        requires :id, type: String, desc: 'The unique identifier for the camera.'
        requires :title, type: String, desc: 'Archive title'
        requires :from_date, type: Integer, desc: 'Archive start timestamp, formatted as either Unix timestamp or ISO8601.'
        requires :to_date, type: Integer, desc: 'Archive end timestamp, formatted as either Unix timestamp or ISO8601.'
        requires :requested_by, type: String, desc: 'The unique identifier for the user who requested archive.'
        optional :embed_time, type: 'Boolean', desc: 'Overlay recording time'
        optional :public, type: 'Boolean', desc: 'Available publically'
      end
      post '/:id/archives' do
        params[:id].downcase!
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        unless rights.allow?(AccessRight::LIST)
          raise AuthorizationError.new if camera.is_public?
          if !rights.allow?(AccessRight::VIEW) && !camera.is_public?
            raise NotFoundError.new
          end
        end

        outcome = Actors::ArchiveCreate.run(params)
        unless outcome.success?
          raise OutcomeError, outcome.to_json
        end
        present Array(outcome.result), with: Presenters::Archive
      end

      #-------------------------------------------------------------------------
      # PATCH /v1/cameras/:id/archives/:archive_id
      #-------------------------------------------------------------------------
      desc 'Updates full or partial data for an existing archive',{
        entity: Evercam::Presenters::Archive
      }
      params do
        requires :id, type: String, desc: 'The unique identifier for the camera.'
        requires :archive_id, type: String, desc: 'The unique identifier for the archive.'
        optional :title, type: String, desc: 'Archive title'
        optional :status, type: Integer, desc: 'Archive status {Pending = > 0, Processing => 1, completed => 2, Failed => 3}'
        optional :public, type: 'Boolean', desc: 'Available publically'
      end
      patch '/:id/archives/:archive_id' do
        params[:id].downcase!
        params[:archive_id].downcase!
        camera = get_cam(params[:id])
        rights = requester_rights_for(camera)
        unless rights.allow?(AccessRight::LIST)
          raise AuthorizationError.new if camera.is_public?
          if !rights.allow?(AccessRight::VIEW) && !camera.is_public?
            raise NotFoundError.new
          end
        end

        outcome = Actors::ArchiveUpdate.run(params)
        unless outcome.success?
          raise OutcomeError, outcome.to_json
        end
        present Array(outcome.result), with: Presenters::Archive
      end

      #-------------------------------------------------------------------------
      # DELETE /v1/cameras/:id/archives/:archive_id
      #-------------------------------------------------------------------------
      desc 'Delete archive from evercam'
      params do
        requires :id, type: String, desc: 'The unique identifier for the camera.'
        requires :archive_id, type: String, desc: 'The unique identifier for the archive.'
      end
      delete '/:id/archives/:archive_id' do
        params[:id].downcase!
        params[:archive_id].downcase!
        camera = get_cam(params[:id])
        raise NotFoundError.new unless camera
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::DELETE)
        archive = ::Archive.where(exid: params[:archive_id])
        raise NotFoundError.new("The '#{params[:archive_id]}' archive does not exist.") if archive.count == 0
        archive.destroy
        {}
      end
    end
  end
end