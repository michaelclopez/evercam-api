require 'rack_helper'
require 'webmock/rspec'
require_app 'api/v1'

describe 'API routes/snapshots' do
  let(:app) { Evercam::APIv1 }

  let(:camera0) do
    camera0 = create(:camera)
    camera0.values[:config].merge!({'external_host' => '89.101.225.158'})
    camera0.values[:config].merge!({'external_http_port' => 8105})
    camera0.location = "0.0 90.0"
    camera0.save
    camera0
  end
  let(:public_camera) do
    public_camera = create(:camera)
    public_camera.location = "0.0 90.0"
    public_camera.is_public = true
    public_camera.is_online = true
    public_camera.discoverable = true
    public_camera.save
    public_camera
  end
  let(:api_keys) { {api_id: camera0.owner.api_id, api_key: camera0.owner.api_key} }
  let(:snap) { create(:snapshot, camera_id: camera0.id, created_at: Time.now.utc, snapshot_id: "#{camera0.id}_#{Time.now.utc.strftime("%Y%m%d%H%M%S%L")}") }
  let(:public_snap) { create(:snapshot, camera: public_camera) }

  let(:other_user) { create(:user) }
  let(:alt_keys) { {api_id: other_user.api_id, api_key: other_user.api_key} }

  describe('GET /cameras/:id/recordings/snapshots') do
    let(:snap1) { create(:snapshot, camera: camera0, created_at: Time.now, snapshot_id: "#{camera0.id}_#{Time.now.utc.strftime("%Y%m%d%H%M%S%L")}") }

    context 'when snapshot request is correct' do
      it 'all snapshots for given camera are returned' do
        skip
        snap1
        get("/cameras/#{snap.camera.exid}/recordings/snapshots", api_keys)
        expect(last_response.status).to eq(200)
        expect(last_response.json['snapshots'].length).to eq(1)
      end
    end

    context 'when unauthenticated' do
      it 'returns an unauthenticated error' do
        get("/cameras/#{camera0.exid}/recordings/snapshots")
        expect(last_response.status).to eq(401)
        data = JSON.parse(last_response.body)
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthenticated")
      end
    end

    context 'when camera is public' do
      it 'doesnt return an unauthorized error' do
        get("/cameras/#{camera0.exid}/recordings/snapshots", alt_keys)
        expect(last_response.status).to eq(200)
        JSON.parse(last_response.body)
      end
    end
  end

  describe "GET /cameras/:id/recordings/snapshots/:year/:month/days" do
    before(:all) do
      @exid     = 'xxx'
      @cam      = create(:camera, exid: @exid)
      @api_keys = {api_id: @cam.owner.api_id, api_key: @cam.owner.api_key}
      (1..150).each do |n|
        Snapshot.create(camera_id: @cam.id, created_at: Time.at(n), snapshot_id: "#{@cam.id}_#{Time.at(n).utc.strftime("%Y%m%d%H%M%S%L")}")
      end
    end

    after(:all) do
      username = @cam.owner.username
      camera = Camera.where(:exid => @exid).first
      snapshots = Snapshot.where(camera_id: camera.id)
      snapshots.delete
      camera.delete
      User.where(:username => username).delete
    end

    describe "GET /cameras/:id/recordings/snapshots/:year/:month/days" do
      context 'when snapshot request is correct' do
        let(:create_snapshot) do
          create(
            :snapshot,
            camera_id: @cam.id,
            created_at: Time.new(1970, 01, 17, 0, 0, 0, '+00:00'),
            snapshot_id: "#{@cam.id}_19700117000000000"
          )
        end
        let(:create_snapshot) { create(:snapshot, camera_id: @cam.id, created_at: Time.new(1970, 01, 17, 0, 0, 0, '+00:00'), snapshot_id: "#{@cam.id}_19700117000000000") }

        it 'returns array of days for given date' do
          create_snapshot
          get("/cameras/#{@exid}/recordings/snapshots/1970/01/days", @api_keys)
          expect(last_response.status).to eq(200)
          expect(last_response.json['days']).to eq([1, 17])
        end
      end

      context 'when month is incorrect' do
        it 'returns 400 error' do
          get("/cameras/#{@exid}/recordings/snapshots/1970/00/days", @api_keys)
          expect(last_response.status).to eq(400)
        end
      end

      context 'when month is incorrect' do
        it 'returns 400 error' do
          get("/cameras/#{@exid}/recordings/snapshots/1970/13/days", @api_keys)
          expect(last_response.status).to eq(400)
        end
      end

      context 'when unauthenticated' do
        it 'returns an unauthenticated error' do
          get("/cameras/#{@exid}/recordings/snapshots/1970/01/days")
          expect(last_response.status).to eq(401)
          data = JSON.parse(last_response.body)
          expect(data.include?("message")).to eq(true)
          expect(data["message"]).to eq("Unauthenticated")
        end
      end

      context 'when camera is public' do
        it 'doesnt return an unauthorized error' do
          get("/cameras/#{@exid}/recordings/snapshots/1970/01/days", api_keys)
          expect(last_response.status).to eq(200)
          JSON.parse(last_response.body)
        end
      end
    end

    describe "GET /cameras/:id/recordings/snapshots/:year/:month/:day/hours" do
      context 'when snapshot request is correct' do
        let(:create_snapshot) do
          create(
            :snapshot,
            camera_id: @cam.id,
            created_at: Time.new(1970, 01, 01, 17, 0, 0, '+00:00'),
            snapshot_id: "#{@cam.id}_19700101170000000"
          )
        end

        it 'returns array of hours for given date' do
          create_snapshot
          get("/cameras/#{@exid}/recordings/snapshots"\
              "/1970/01/01/hours",
              @api_keys)
          expect(last_response.status).to eq(200)
          expect(last_response.json['hours']).to eq([0, 17])
        end
      end

      context 'when day is incorrect' do
        it 'returns 400 error' do
          get("/cameras/#{@exid}/recordings/snapshots/1970/01/00/hours",
              @api_keys)
          expect(last_response.status).to eq(400)
        end
      end

      context 'when day is incorrect' do
        it 'returns 400 error' do
          get("/cameras/#{@exid}/recordings/snapshots/1970/01/41/hours",
              @api_keys)
          expect(last_response.status).to eq(400)
        end
      end

      context 'when unauthenticated' do
        it 'returns an unauthenticated error' do
          get("/cameras/#{@exid}/recordings/snapshots/1970/01/01/hours")
          expect(last_response.status).to eq(401)
          data = JSON.parse(last_response.body)
          expect(data.include?("message")).to eq(true)
          expect(data["message"]).to eq("Unauthenticated")
        end
      end

      context 'when camera is public' do
        it 'doesnt return an unauthorized error' do
          get("/cameras/#{@exid}/recordings/snapshots/1970/01/01/hours",
              api_keys)
          expect(last_response.status).to eq(200)
          JSON.parse(last_response.body)
        end
      end
    end

    context 'when snapshot request is correct' do
      context 'all snapshots within given range are returned' do
        it 'applies default no data limit' do
          get("/cameras/#{@exid}/recordings/snapshots",
              { from: 1, to: 1234567890 }.merge(@api_keys))
          expect(last_response.status).to eq(200)
          expect(last_response.json["snapshots"].length).to eq(100)
        end

        it 'applies default no data limit and returns second page' do
          get("/cameras/#{@exid}/recordings/snapshots",
              { from: 1, to: 1234567890, page: 2 }.merge(@api_keys))
          expect(last_response.status).to eq(200)
          expect(last_response.json["snapshots"].length).to eq(50)
        end

        it 'applies specified limit' do
          get("/cameras/#{@exid}/recordings/snapshots",
              { from: 1, to: 1234567890, limit: 15 }.merge(@api_keys))
          expect(last_response.status).to eq(200)
          expect(last_response.json["snapshots"].length).to eq(15)
        end

        it 'applies default data limit' do
          get("/cameras/#{@exid}/recordings/snapshots",
              { from: 1, to: 1234567890, with_data: true }.merge(@api_keys))
          expect(last_response.status).to eq(200)
          expect(last_response.json["snapshots"].length).to eq(100)
        end

        it 'applies specified limit' do
          get("/cameras/#{@exid}/recordings/snapshots",
              { from: 1, to: 1234567890, with_data: true, limit: 5
              }.merge(@api_keys))
          expect(last_response.status).to eq(200)
          expect(last_response.json["snapshots"].length).to eq(5)
        end

        it 'returns only two entries' do
          get("/cameras/#{@exid}/recordings/snapshots",
              { from: 1, to: 2 }.merge(@api_keys))
          expect(last_response.status).to eq(200)
          expect(last_response.json["snapshots"].length).to eq(2)
        end
      end
    end
  end

  describe "GET /cameras/:id/recordings/snapshots/latest" do
    let(:camera1) do
      camera1 = create(:camera, is_public: false)
      camera1.values[:config].merge!({'external_host' => '89.101.225.158'})
      camera1.values[:config].merge!({'external_http_port' => 8105})
      camera1.save
      camera1
    end
    let(:auth) { {api_id: camera1.owner.api_id, api_key: camera1.owner.api_key} }

    context 'when snapshot request is correct but there are no snapshots' do
      it 'empty list is returned' do
        get("/cameras/#{camera1.exid}/recordings/snapshots/latest", auth)
        expect(last_response.status).to eq(200)
        expect(last_response.json["snapshots"].length).to eq(0)
      end
    end

    let(:instant) { Time.now.utc }
    let(:snap1) { create(:snapshot, camera_id: camera0.id, created_at: instant, snapshot_id: "#{camera0.id}_#{instant.strftime("%Y%m%d%H%M%S%L")}") }
    let(:snap2) { create(:snapshot, camera_id: camera0.id, created_at: instant - 1000, snapshot_id: "#{camera0.id}_#{(instant - 1000).strftime("%Y%m%d%H%M%S%L")}") }
    let(:snap3) { create(:snapshot, camera_id: camera0.id, created_at: instant + 1000, snapshot_id: "#{camera0.id}_#{(instant + 1000).strftime("%Y%m%d%H%M%S%L")}") }
    let(:other_user) { create(:user) }

    context 'when snapshot request is correct' do
      it 'latest snapshot for given camera is returned' do
        snap1
        snap2
        snap3
        get("/cameras/#{camera0.exid}/recordings/snapshots/latest",
            api_keys)
        expect(last_response.status).to eq(200)
        expect(last_response.json["snapshots"][0]["created_at"]).to eq(snap3.created_at.to_i)
        # expect(last_response.json['timezone']).to eq('Etc/UTC')
      end
    end

    context 'when unauthenticated' do
      it 'returns an unauthenticated error' do
        get("/cameras/#{camera1.exid}/recordings/snapshots/latest")
        expect(last_response.status).to eq(401)
        data = JSON.parse(last_response.body)
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthenticated")
      end
    end

    context 'when camera is public' do
      it 'doesnt return an unauthorized error' do
        get("/cameras/#snap.camera.exid/recordings/snapshots/latest",
            api_id: other_user.api_id, api_key: other_user.api_key)
        expect(last_response.status).to eq(200)
        JSON.parse(last_response.body)
      end
    end
  end

  describe 'GET /cameras/:id/live' do
    context 'when snapshot request is correct' do
      context 'and camera is online' do
        it 'returns snapshot jpg' do
          skip
          stub_request(:get, /.*89.101.225.158:8105.*/).
            to_return(:status => 200, :body => "", :headers => {})

          get("/cameras/#{snap.camera.exid}/live/snapshot", api_keys)
          expect(last_response.status).to eq(200)
        end
      end

      context 'and camera is online and requires basic auth' do
        context 'auth is not provided' do
          it 'returns 403 error' do
            skip
            stub_request(:get, /.*89.101.225.158:8105.*/).
              to_return(:status => 401, :body => "", :headers => {})

            snap.camera.values[:config]['snapshots'] = { jpg: '/Streaming/channels/1/picture'}
            snap.camera.values[:config]['auth'] = {}
            snap.camera.save
            get("/cameras/#{snap.camera.exid}/live/snapshot", api_keys)
            expect(last_response.status).to eq(403)
          end
        end

        context 'auth is provided' do
          it 'returns snapshot jpg' do
            skip
            stub_request(:get, /.*89.101.225.158:8105.*/).
              to_return(:status => 200, :body => "", :headers => {})

            snap.camera.values[:config]['snapshots'] = { jpg: '/Streaming/channels/1/picture'}
            snap.camera.values[:config]['auth'] = {basic: {username: 'admin', password: 'mehcam'}}
            snap.camera.save
            get("/cameras/#{snap.camera.exid}/live/snapshot", api_keys)
            expect(last_response.status).to eq(200)
          end
        end
      end

      context 'and camera is offline' do
        it '503 error is returned' do
          skip
          stub_request(:get, "http://89.101.225.158:8105/onvif/snapshot").
            to_return(:status => 500, :body => nil, :headers => {})

          response = Typhoeus::Response.new(:return_code => :operation_timedout)
          Typhoeus.stub(/#{camera0.external_url}/).and_return(response)
          get("/cameras/#{snap.camera.exid}/live", api_keys)
          expect(last_response.status).to eq(503)
        end
      end
    end

    context 'when snapshot request is not authorized' do
      it 'request is not authorized' do
        skip
        camera0.is_public = false
        camera0.save
        get("/cameras/#{snap.camera.exid}/live")
        expect(last_response.status).to eq(401)
      end
    end
  end

  describe 'GET /cameras/:id/snapshot.jpg' do
    context 'when snapshot request is correct' do
      it 'redirects to snapshot server' do
        skip
        get("/cameras/#{snap.camera.exid}/live/snapshot.jpg")
        expect(last_response.status).to eq(302)
        expect(last_response.location).to start_with("#{Evercam::Config[:snapshots][:url]}#{snap.camera.exid}.jpg?t=")
      end
    end

    context 'when snapshot request is not authorized' do
      it 'request is not authorized' do
        skip
        camera0.is_public = false
        camera0.save
        get("/cameras/#{snap.camera.exid}/snapshot.jpg")
        expect(last_response.status).to eq(403)
      end
    end
  end

  describe 'GET /public/nearest.jpg' do
    context 'when snapshot request is correct' do
      it 'redirects to snapshot server' do
        skip
        public_camera
        get("/public/cameras/nearest/snapshot")
        expect(last_response.status).to eq(302)
        expect(last_response.location).
          to start_with("#{Evercam::Config[:snapshots][:url]}#{public_snap.camera.exid}.jpg?t=")
      end
    end
  end

  describe "GET /cameras/:id/recordings/snapshots/:timestamp" do
    context 'when snapshot request is correct' do
      let(:instant) { Time.now.utc }
      let(:s0) { create(:snapshot, camera_id: camera0.id, created_at: instant, snapshot_id: "#{camera0.id}_#{instant.strftime("%Y%m%d%H%M%S%L")}") }
      let(:s1) { create(:snapshot, camera_id: camera0.id, created_at: instant + 1, snapshot_id: "#{camera0.id}_#{(instant + 1).strftime("%Y%m%d%H%M%S%L")}") }
      let(:s2) { create(:snapshot, camera_id: camera0.id, created_at: instant + 2, snapshot_id: "#{camera0.id}_#{(instant + 2).strftime("%Y%m%d%H%M%S%L")}") }

      before do
        s0
        s1
        s2

        stub_request(:get, /.*evercam-camera-assets.s3.amazonaws.com.*/).
          to_return(:status => 201, :body => "", :headers => {})
      end

      context 'range is specified' do
        it 'latest snapshot is returned' do
          get("/cameras/#{camera0.exid}/recordings/"\
              "snapshots/#{s0.created_at.to_i}",
              { range: 10 }.merge(api_keys))
          expect(last_response.json['snapshots'][0]['data']).to be_nil
          expect(last_response.json['snapshots'][0]['created_at']).to eq(s0.created_at.to_i)
          expect(last_response.status).to eq(200)
        end
      end

      context 'range is not specified' do
        it 'specific snapshot is returned' do
          get("/cameras/#{camera0.exid}/recordings/"\
              "snapshots/#{s1.created_at.to_i}",
              api_keys)
          expect(last_response.json['snapshots'][0]['data']).to be_nil
          expect(last_response.json['snapshots'][0]['created_at']).to eq(s1.created_at.to_i)
          expect(last_response.status).to eq(200)
        end
      end

      context 'type is not specified' do
        it 'snapshot without image data is returned' do
          get("/cameras/#{camera0.exid}/recordings/"\
              "snapshots/#{snap.created_at.to_i}",
              api_keys)
          expect(last_response.json['snapshots'][0]['data']).to be_nil
          expect(last_response.status).to eq(200)
        end
      end

      context 'when unauthenticated' do
        it 'returns an unauthenticated error' do
          get("/cameras/#{camera0.exid}/recordings/"\
              "snapshots/#{s0.created_at.to_i}",
              range: 10)
          expect(last_response.status).to eq(401)
          data = JSON.parse(last_response.body)
          expect(data.include?("message")).to eq(true)
          expect(data["message"]).to eq("Unauthenticated")
        end
      end

      context 'when camera is public' do
        it 'doesnt return an unauthorized error' do
          other_user = create(:user)
          parameters = {range: 10, api_id: other_user.api_id, api_key: other_user.api_key}
          get("/cameras/#{camera0.exid}/recordings/"\
              "snapshots/#{s0.created_at.to_i}",
              parameters)
          expect(last_response.status).to eq(200)
          JSON.parse(last_response.body)
        end
      end
    end
  end

  describe 'POST /cameras/:id/snapshots' do
    let(:params) do
      {
        notes: 'Snap note'
      }
    end

    context 'when snapshot request is correct' do
      it 'returns 200 OK status' do
        skip
        stub_request(:get, "http://abcd:wxyz@89.101.225.158:8105/onvif/snapshot").
          to_return(:status => 200, :body => "", :headers => {})
        stub_request(:put, /.*evercam-camera-assets.s3.amazonaws.com.*/).
          to_return(:status => 201, :body => "", :headers => {})

        post("/cameras/#{camera0.exid}/recordings/snapshots",
             params.merge(api_keys))
        expect(last_response.status).to eq(201)
      end

      it 'saves snapshot' do
        skip
        stub_request(:get, "http://abcd:wxyz@89.101.225.158:8105/onvif/snapshot").
          to_return(:status => 200, :body => "", :headers => {})
        stub_request(:put, /.*evercam-camera-assets.s3.amazonaws.com.*/).
          to_return(:status => 200, :body => "", :headers => {})

        post("/cameras/#{camera0.exid}/recordings/snapshots",
             params.merge(api_keys))
        snap = Snapshot.first
        expect(snap.notes).to eq(params[:notes])
        expect(snap.created_at).to be_around_now
        expect(snap.camera.exid).to eq(camera0.exid)
      end

      it 'returns the snapshot' do
        skip
        stub_request(:get, "http://abcd:wxyz@89.101.225.158:8105/onvif/snapshot").
          to_return(:status => 200, :body => "", :headers => {})
        stub_request(:put, /.*evercam-camera-assets.s3.amazonaws.com.*/).
          to_return(:status => 200, :body => "", :headers => {})

        post("/cameras/#{camera0.exid}/recordings/snapshots",
             params.merge(api_keys))
        res = last_response.json['snapshots'][0]
        expect(res['notes']).to eq(params[:notes])
        expect(Time.at(res['created_at'])).to be_around_now
      end
    end
  end

  describe "POST /cameras/:id/recordings/snapshots/:timestamp" do
    let(:params) do
      {
        notes: 'Snap note',
        data: Rack::Test::UploadedFile.new('spec/resources/snapshot.jpg', 'image/jpeg')
      }
    end

    context 'when snapshot request is correct' do
      it 'snapshot is saved' do
        skip
        stub_request(:put, /.*evercam-camera-assets.s3.amazonaws.com.*/).
          to_return(:status => 200, :body => "", :headers => {})

        post("/cameras/#{camera0.exid}/recordings/snapshots/12345678",
             params.merge(api_keys))
        expect(last_response.status).to eq(201)
        snap = Snapshot.first
        expect(snap.notes).to eq('Snap note')
        expect(snap.created_at).to be_around_now
        expect(snap.camera.exid).to eq(camera0.exid)
        expect(snap.data).not_to be_nil
      end
    end

    context 'when data has incorrect file format' do
      it 'error is returned' do
        post("/cameras/#{camera0.exid}/recordings/snapshots/12345678",
             params.merge(data: Rack::Test::UploadedFile.new('.gitignore', 'text/plain')).merge(api_keys))
        expect(last_response.status).to eq(400)
      end
    end

    context 'when unauthenticated' do
      it 'returns an unauthenticated error' do
        post("/cameras/#{camera0.exid}/recordings/snapshots/12345678", params)
        expect(last_response.status).to eq(401)
        data = JSON.parse(last_response.body)
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthenticated")
      end
    end

    context 'when unauthorized' do
      let(:camera3) { create(:camera, is_public: false) }

      it 'returns an unauthorized error' do
        post("/cameras/#{camera3.exid}/recordings/snapshots/12345678", params.merge(alt_keys))
        expect(last_response.status).to eq(403)
        data = JSON.parse(last_response.body)
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthorized")
      end
    end
  end

  describe 'DELETE /cameras/:id/recordings/snapshots/:timestamp' do
    context 'when snapshot request is correct' do
      it 'snapshot is deleted' do
        delete("/cameras/#{camera0.exid}/recordings/snapshots/#{snap.created_at.to_i}", api_keys)
        expect(last_response.status).to eq(200)
        expect(Snapshot.first).to be_nil
      end
    end

    context 'when unauthenticated' do
      it 'returns an unauthenticated error' do
        delete("/cameras/#{camera0.exid}/recordings"\
               "/snapshots/#{snap.created_at.to_i}")
        expect(last_response.status).to eq(401)
        data = JSON.parse(last_response.body)
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthenticated")
      end
    end

    context 'when unauthorized' do
      it 'returns an unauthorized error' do
        delete("/cameras/#{camera0.exid}/recordings/"\
               "snapshots/#{snap.created_at.to_i}",
               alt_keys)
        expect(last_response.status).to eq(403)
        data = JSON.parse(last_response.body)
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthorized")
      end
    end
  end
end
