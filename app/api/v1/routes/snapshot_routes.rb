require 'typhoeus'
require_relative '../presenters/snapshot_presenter'

module Evercam
  class V1SnapshotRoutes < Grape::API
    include WebErrors

    DEFAULT_LIMIT_WITH_DATA = 10
    DEFAULT_LIMIT_NO_DATA = 100
    MAXIMUM_LIMIT = 10000

    namespace :cameras do
      before do
        authorize!
        header "Access-Control-Allow-Origin", "*"
      end

      params do
        requires :id, type: String, desc: "Camera Id."
      end
      route_param :id do
        #-------------------------------------------------------------------
        # GET /v1/cameras/:id/recordings/snapshots
        #-------------------------------------------------------------------
        desc 'Returns the list of all snapshots currently stored for this camera'
        params do
          requires :id, type: String, desc: "Unique identifier for the camera"
          optional :from, type: Integer, desc: "From Unix timestamp."
          optional :to, type: Integer, desc: "To Unix timestamp."
          optional :limit, type: Integer, desc: "The maximum number of cameras to retrieve. Defaults to #{DEFAULT_LIMIT_NO_DATA}, cannot be more than #{MAXIMUM_LIMIT}."
          optional :page, type: Integer, desc: "Page number, starting from 0"
        end
        get 'recordings/snapshots' do
          params[:id].downcase!
          camera = get_cam(params[:id])

          rights = requester_rights_for(camera)
          raise AuthorizationError.new unless rights.allow?(AccessRight::LIST)

          limit = params[:limit] || DEFAULT_LIMIT_NO_DATA
          limit = DEFAULT_LIMIT_NO_DATA if limit < 1 or limit > MAXIMUM_LIMIT

          page = params[:page].to_i || 0
          page = 0 if page < 0
          offset = (page - 1) * limit
          offset = 0 if offset < 0

          from_time = Time.at(params[:from].to_i).utc
          to_time = Time.at(params[:to].to_i).utc
          to_time = Time.now.utc if params[:to].blank?

          off_set = Time.now.in_time_zone(camera.timezone.zone).strftime("%:z")
          from = Time.new(from_time.year, from_time.month, from_time.day, from_time.hour, from_time.min, from_time.sec, off_set).utc
          to = Time.new(to_time.year, to_time.month, to_time.day, to_time.hour, to_time.min, to_time.sec, off_set).utc

          query = Snapshot.where(:snapshot_id => "#{camera.id}_#{from.strftime("%Y%m%d%H%M%S%L")}".."#{camera.id}_#{to.strftime("%Y%m%d%H%M%S%L")}")
                    .select(:notes, :created_at, :motionlevel, :snapshot_id).order(:snapshot_id)

          count = query.count
          total_pages = count / limit
          total_pages += 1 unless count % limit == 0
          snapshots = query.limit(limit).offset(offset).all

          present(snapshots, with: Presenters::Snapshot).merge!(pages: total_pages)
        end

        #-------------------------------------------------------------------
        # GET /v1/cameras/:id/recordings/snapshots/latest
        #-------------------------------------------------------------------
        desc 'Returns latest snapshot stored for this camera', {
          entity: Evercam::Presenters::Snapshot
        }
        params do
          optional :with_data, type: 'Boolean', desc: "Should it send image data?"
        end
        get 'recordings/snapshots/latest' do
          params[:id].downcase!
          camera = get_cam(params[:id])

          snapshot = Snapshot.where(snapshot_id: "#{camera.id.to_i}_2000".."#{camera.id.to_i}_2999").order(:snapshot_id).last
          if snapshot
            rights = requester_rights_for(camera)
            raise AuthorizationError.new unless rights.allow?(AccessRight::LIST)
            present(Array(snapshot), with: Presenters::Snapshot, with_data: params[:with_data], exid: camera.exid)
          else
            present([], with: Presenters::Snapshot, with_data: params[:with_data], exid: camera.exid)
          end
        end

        #-------------------------------------------------------------------
        # GET /v1/cameras/:id/recordings/snapshots/:year/:month/days
        #-------------------------------------------------------------------
        desc 'Returns list of specific days in a given month which contains any snapshots'
        params do
          requires :year, type: Integer, desc: "Year, for example 2013"
          requires :month, type: Integer, desc: "Month, for example 11"
        end
        get 'recordings/snapshots/:year/:month/days' do
          unless (1..12).include?(params[:month])
            raise BadRequestError, 'Invalid month value'
          end
          params[:id].downcase!
          camera = get_cam(params[:id])

          rights = requester_rights_for(camera)
          raise AuthorizationError.new unless rights.allow?(AccessRight::LIST)

          offset = Time.now.in_time_zone(camera.timezone.zone).strftime("%:z")

          cache_key = "snapshots|days|#{params.slice(:id, :year, :month).flatten.join('|')}"
          days = Evercam::Services.dalli_cache.get(cache_key)
          if days.nil?
            days = []
            (1..Date.new(params[:year], params[:month], -1).day).each do |day|
              from = Time.new(params[:year], params[:month], day, 0, 0, 0, offset).utc.to_s
              if Snapshot.db.select(Snapshot.where(Sequel.like(:snapshot_id, "#{camera.id}_#{Time.parse(from).utc.strftime("%Y%m%d")}%")).exists).first[:exists]
                days << day
              end
            end
            Evercam::Services.dalli_cache.set(cache_key, days)
          end

          { :days => days }
        end

        #-------------------------------------------------------------------
        # GET /v1/cameras/:id/recordings/snapshots/:year/:month/:day/hours
        #-------------------------------------------------------------------
        desc 'Returns list of specific hours in a given day which contains any snapshots'
        params do
          requires :year, type: Integer, desc: "Year, for example 2013"
          requires :month, type: Integer, desc: "Month, for example 11"
          requires :day, type: Integer, desc: "Day, for example 17"
        end
        get 'recordings/snapshots/:year/:month/:day/hours' do
          unless (1..12).include?(params[:month])
            raise BadRequestError, 'Invalid month value'
          end
          unless (1..31).include?(params[:day])
            raise BadRequestError, 'Invalid day value'
          end
          params[:id].downcase!
          camera = get_cam(params[:id])

          rights = requester_rights_for(camera)
          raise AuthorizationError.new unless rights.allow?(AccessRight::LIST)

          offset = Time.now.in_time_zone(camera.timezone.zone).strftime("%:z")

          # cache_key = "snapshots|days|#{params.slice(:id, :year, :month, :day).flatten.join('|')}"
          # hours = Evercam::Services.dalli_cache.get(cache_key)
          # if hours.nil?
          hours = []
          (0..23).each do |hour|
            from = Time.new(params[:year], params[:month], params[:day], hour, 0, 0, offset).utc
            to = Time.new(params[:year], params[:month], params[:day], hour, 59, 59, offset).utc

            if Snapshot.db.select(Snapshot.where(:snapshot_id => "#{camera.id}_#{from.strftime("%Y%m%d%H%M%S%L")}".."#{camera.id}_#{to.strftime("%Y%m%d%H%M%S%L")}").exists).first[:exists]
              hours << hour
            end
          end
          # end

          { :hours => hours }
        end

        #-------------------------------------------------------------------
        # GET /v1/cameras/:id/recordings/snapshots/:timestamp
        #-------------------------------------------------------------------
        desc 'Returns the snapshot stored for this camera closest to the given timestamp', {
          entity: Evercam::Presenters::Snapshot
        }
        params do
          requires :timestamp, type: String, desc: "Snapshot timestamp, formatted as either Unix timestamp or ISO8601."
          optional :with_data, type: 'Boolean', desc: "Should it send image data?"
          optional :range, type: Integer, desc: "Time range in seconds around specified timestamp. Default range is one second (so it matches only exact timestamp)."
        end
        get 'recordings/snapshots/:timestamp' do
          params[:id].downcase!
          camera = get_cam(params[:id])
          rights   = requester_rights_for(camera)
          raise AuthorizationError.new unless rights.allow?(AccessRight::LIST)

          if Evercam::Utils.is_num?(params["timestamp"])
            timestamp = Time.at(params[:timestamp].to_i).utc
          else
            timestamp = ActiveSupport::TimeZone.new('UTC').parse(params[:timestamp])
          end
          range = params[:range].to_i
          if range < 1
            range = 1
          end
          from = timestamp - range + 1
          to = timestamp + range
          snapshot = Snapshot.where(snapshot_id: "#{camera.id}_#{from.strftime("%Y%m%d%H%M%S%L")}".."#{camera.id}_#{to.strftime("%Y%m%d%H%M%S%L")}").first
          if params[:with_data]
            filepath = "#{camera.exid}/snapshots/#{snapshot.created_at.to_i}.jpg"
            s3_object = Evercam::Services.snapshot_bucket.objects[filepath]
            if s3_object.exists?
              image = s3_object.read
            else
              url = "#{Evercam::Config[:snapshots][:url]}v1/cameras/#{camera.exid}/recordings/snapshots/data/#{snapshot.snapshot_id}?notes=#{snapshot.notes}"
              conn = Faraday.new(url: url) do |faraday|
                faraday.adapter Faraday.default_adapter
              end
              response = conn.get
              image = response.body
              status 203 if response.status != 200
            end
            data = Base64.encode64(image).gsub("\n", '')
            image = "data:image/jpeg;base64,#{data}"
          end

          present(Array(snapshot), with: Presenters::Snapshot, with_data: params[:with_data], image: image, exid: camera.exid)
        end

        #-------------------------------------------------------------------
        # DELETE /v1/cameras/:id/recordings/snapshots/:timestamp
        #-------------------------------------------------------------------
        desc 'Deletes any snapshot for this camera which exactly matches the timestamp'
        params do
          requires :timestamp, type: Integer, desc: "Snapshot Unix timestamp."
        end
        delete 'recordings/snapshots/:timestamp' do
          params[:id].downcase!
          camera = get_cam(params[:id])

          rights = requester_rights_for(camera.owner, AccessRight::SNAPSHOTS)
          raise AuthorizationError.new if !rights.allow?(AccessRight::DELETE)

          name = nil
          unless access_token.nil?
            token_user = User.where(id: access_token.user_id).first
            name = token_user.fullname unless token_user.nil?
          end
          CameraActivity.create(
            camera_id: camera.id,
            camera_exid: camera.exid,
            access_token_id: (access_token.nil? ? nil : access_token.id),
            name: (access_token.nil? ? nil : name),
            action: 'deleted snapshot',
            done_at: Time.now,
            ip: request.ip
          )

          snapshot_timestamp = Time.at(params[:timestamp].to_i).utc.strftime("%Y%m%d%H%M%S")
          snapshot_id = "#{camera.id}_#{snapshot_timestamp}"
          snapshot_query = Sequel.ilike(:snapshot_id, "#{snapshot_id}%")
          Snapshot.where(snapshot_query).delete
          {}
        end
      end
    end

    namespace :cameras do
      before do
        header "Access-Control-Allow-Origin", "*"
      end

      #-------------------------------------------------------------------
      # GET /v1/cameras/:id/live/snapshot
      #-------------------------------------------------------------------
      desc 'Returns jpg from the camera'
      params do
        requires :id, type: String, desc: "Camera Id."
      end
      route_param :id do
        get '/live/snapshot' do
          params[:id].downcase!

          id = params.fetch('id', '')
          api_id = params.fetch('api_id', '')
          api_key = params.fetch('api_key', '')
          authorization = request.headers["Authorization"]
          url = "#{Evercam::Config[:snapshots][:url]}v1/cameras/#{id}/live/snapshot?api_id=#{api_id}&api_key=#{api_key}"
          url = "#{url}&authorization=#{authorization}" unless authorization.blank?

          redirect url
        end
      end

      #-------------------------------------------------------------------
      # POST /v1/cameras/:id/recordings/snapshots
      #-------------------------------------------------------------------
      desc 'Fetches a snapshot from the camera and stores it using the current timestamp'
      params do
        requires :id, type: String, desc: "Camera Id."
        optional :notes, type: String, desc: "Optional text note for this snapshot"
        optional :with_data, type: 'Boolean', desc: "Should it return image data?"
      end
      route_param :id do
        post 'recordings/snapshots' do
          params[:id].downcase!

          id = params.fetch('id', '')
          api_id = params.fetch('api_id', '')
          api_key = params.fetch('api_key', '')
          notes = params.fetch('notes', '')
          with_data = params.fetch('with_data', '')
          authorization = request.headers["Authorization"]

          url = "#{Evercam::Config[:snapshots][:url]}v1/cameras/#{id}/recordings/snapshots?api_id=#{api_id}&api_key=#{api_key}&notes=#{notes}&with_data=#{with_data}"

          conn = Faraday.new(url: url) do |faraday|
            faraday.adapter Faraday.default_adapter
            faraday.options.timeout = 10
            faraday.options.open_timeout = 10
          end

          begin
            if authorization.blank?
              response = conn.post
            else
              response = conn.post do |req|
                req.headers["Authorization"] = request.headers["Authorization"]
              end
            end
            status response.status
            JSON.parse response.body
          rescue JSON::ParserError
            status 500
            {message: "Error parsing response from Evercam Media."}
          rescue Faraday::TimeoutError
            status 504
            {message: "Connecting to Evercam Media timed out."}
          end
        end
      end

      #-------------------------------------------------------------------
      # GET /v1/cameras/:id/recordings/snapshots/:year/:month/:day
      #-------------------------------------------------------------------
      desc 'Returns list of specific days in a given month which contains any snapshots'
      params do
        requires :id, type: String, desc: "Camera Id."
        requires :year, type: Integer, desc: "Year, for example 2013"
        requires :month, type: Integer, desc: "Month, for example 11"
        requires :day, type: Integer, desc: "Day, for example 17"
      end
      get ':id/recordings/snapshots/:year/:month/:day' do
        params[:id].downcase!
        user_cache_key = "#{params[:api_id]}|snapshots|day|#{params.slice(:id, :year, :month, :day).flatten.join('|')}"
        exists = Evercam::Services.dalli_cache.get(user_cache_key)

        if exists.nil?
          unless (1..12).include?(params[:month])
            raise BadRequestError, 'Invalid month value'
          end
          unless (1..31).include?(params[:day])
            raise BadRequestError, 'Invalid day value'
          end
          camera = get_cam(params[:id])

          rights = requester_rights_for(camera)
          raise AuthorizationError.new unless rights.allow?(AccessRight::LIST)

          offset = Time.now.in_time_zone(camera.timezone.zone).strftime("%:z")

          cache_key = "snapshots|day|#{params.slice(:id, :year, :month, :day).flatten.join('|')}"
          exists = Evercam::Services.dalli_cache.get(cache_key)

          if exists.nil?
            from = Time.new(params[:year], params[:month], params[:day], 0, 0, 0, offset).utc
            to = Time.new(params[:year], params[:month], params[:day], 23, 59, 59, offset).utc

            exists = Snapshot.db.select(Snapshot.where(:snapshot_id => "#{camera.id}_#{from.strftime("%Y%m%d%H%M%S%L")}".."#{camera.id}_#{to.strftime("%Y%m%d%H%M%S%L")}").exists).first[:exists]

            unless from.today? || from.future?
              Evercam::Services.dalli_cache.set(cache_key, exists, 1.years)
              Evercam::Services.dalli_cache.set(user_cache_key, exists, 1.years)
            end
          end
        end

        { exists: exists }
      end
    end

    namespace :public do
      #-------------------------------------------------------------------
      # GET /v1/public/cameras/nearest/snapshot
      #-------------------------------------------------------------------
      desc "Returns jpg from nearest publicly discoverable camera from within the Evercam system."\
        "If location isn't provided requester's IP address is used.", {
      }
      params do
        optional :near_to, type: String, desc: "Specify an address or latitude longitude points."
      end
      get 'cameras/nearest/snapshot' do
        begin
          if params[:near_to]
            location = {
              latitude: Geocoding.as_point(params[:near_to]).y,
              longitude: Geocoding.as_point(params[:near_to]).x
            }
          else
            location = {
              latitude: request.location.latitude,
              longitude: request.location.longitude
            }
          end
        rescue => error
          raise_error(400, 400, error.message)
        end

        if params[:near_to] || request.location
          camera = Camera.nearest(location).limit(1).first
        else
          raise_error(400, 400, "Location is missing")
        end

        redirect "#{Evercam::Config[:snapshots][:url]}v1/cameras/#{camera.exid}/live/snapshot"
      end
    end
  end

  class V1SnapshotJpgRoutes < Grape::API
    content_type :img, "image/jpg"
    format :img

    namespace :cameras do
      params do
        requires :id, type: String, desc: "Camera Id."
      end
      route_param :id do
        desc 'Returns jpg from the camera'
        get 'recordings/snapshots/latest/jpg' do
          params[:id].downcase!
          camera = get_cam(params[:id])

          rights = requester_rights_for(camera)
          raise AuthorizationError.new if !rights.allow?(AccessRight::SNAPSHOT)

          snapshot = Snapshot.where(snapshot_id: "#{camera.id.to_i}_2000".."#{camera.id.to_i}_2999").order(:snapshot_id).last
          raise NotFoundError.new if snapshot.nil?

          filepath = "#{camera.exid}/snapshots/#{snapshot.created_at.to_i}.jpg"

          snapshot_file = Evercam::Services.snapshot_bucket.objects[filepath]
          if snapshot_file.exists?
            snapshot_file.read
          else
            url = "#{Evercam::Config[:snapshots][:url]}v1/cameras/#{camera.exid}/recordings/snapshots/data/#{snapshot.snapshot_id}"
            conn = Faraday.new(url: url) do |faraday|
              faraday.adapter Faraday.default_adapter
            end
            response = conn.get
            response.body
          end
        end
      end
    end
  end
end
