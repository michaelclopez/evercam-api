require 'rack_helper'
require_app 'api/v1'

describe 'API routes/users' do
  let(:app) { Evercam::APIv1 }

  let(:params) do
    {
      firstname: 'Garrett',
      lastname: 'Heaver',
      username: 'garrettheaver',
      email: 'garrett@evercam.io',
      password: 'password',
      country: create(:country).iso3166_a2
    }
  end

  let(:patch_params) do
    {
      firstname: 'G',
      lastname: 'H',
      email: 'gh@evercam.io',
      password: 'password123',
      country: create(:country).iso3166_a2
    }
  end

  let(:blank_params) do
    {
      firstname: '',
      lastname: '',
      username: '',
      email: '',
      password: '',
      country: ''
    }
  end

  let(:other_user) { create(:user) }
  let(:alt_keys) { {api_id: other_user.api_id, api_key: other_user.api_key} }

  describe 'GET /testusername' do
    let!(:user0) { create(:user, username: 'xxxx', email: 'xxxx@gmail.com') }
    let(:api_keys) { {api_id: user0.api_id, api_key: user0.api_key} }

    context 'when username is already in use' do
      it 'returns 400 error ' do
        get("/testusername?username=#{user0.username}", api_keys)

        expect(last_response.status).to eq(400)
      end
    end

    context 'when username is not in use' do
      it 'returns a 200 OK status' do
        get("/testusername?username=unique", api_keys)
        expect(last_response.status).to eq(200)
      end
    end

    context 'when email is already in use' do
      it 'returns 400 error ' do
        get("/testusername?username=#{user0.email}", api_keys)

        expect(last_response.status).to eq(400)
      end
    end

    context 'when email is not in use' do
      it 'returns a 200 OK status' do
        get("/testusername?username=unique@gmail.com", api_keys)
        expect(last_response.status).to eq(200)
      end
    end

    context 'when not authenticated' do
      it 'returns an unauthenticated error' do
        get("/testusername?username=unique")
        expect(last_response.status).to eq(200)
      end
    end

  end

  describe 'POST /users' do

    let(:user) { create(:user) }

    context 'when the params are valid' do
      it 'creates the user and returns the json' do
        post('/users', params)

        expect(last_response.status).to eq(201)
        response0 = last_response.json['users'][0]

        expect(response0).to have_keys(
          'id', 'firstname', 'lastname', 'username', 'email',
          'country', 'created_at', 'updated_at', 'confirmed_at')
      end
    end

    context 'when the username or email already exists' do
      it 'returns a conflict error for a duplicate user name' do
        create(:user, username: 'xxxx')
        post('/users', params.merge(username: 'xxxx'))
        expect(last_response.status).to eq(409)
        data = last_response.json
        expect(data["message"]).to eq("The username 'xxxx' is already registered.")
      end

      it 'returns a conflict error for a duplicate email address' do
        user = create(:user)
        post('/users', params.merge(email: user.email))
        expect(last_response.status).to eq(409)
        data = last_response.json
        expect(data["message"]).to eq("The email address '#{user.email}' is already registered.")
      end
    end

    context 'when params are blank' do
      it 'returns a 400 BAD Request status' do
        post('/users', blank_params)
        expect(last_response.status).to eq(400)
      end
    end

    context 'when the country code does not exist' do
      it 'returns a 400 BAD Request status' do
        post('/users', params.merge(country: 'xx'))
        expect(last_response.status).to eq(400)
        data = last_response.json
        expect(data["message"]).to eq("Invalid parameters specified to request.")
      end
    end

    context 'when the country code is in capital letters' do
      it 'returns a 400 BAD Request status' do
        params[:country].upcase!
        post('/users', params)
        expect(last_response.status).to eq(400)
      end
    end
  end

  describe 'GET /users/{username}' do
    let!(:user0) { create(:user, username: 'xxxx', password: 'yyyy') }
    let(:api_keys) { {api_id: user0.api_id, api_key: user0.api_key} }

    context 'when the user does not exist' do
      it 'returns a NOT FOUND status' do
        expect(get("/users/notexisitngid", api_keys).status).to eq(404)
      end
    end

    context 'with no authentication information' do
      before(:each) { get("/users/#{user0.username}") }

      it 'returns 401' do
        expect(last_response.status).to eq(401)
      end
    end

    context 'when the authenticated user is the owner' do
      before(:each) do
        get("/users/#{user0.username}", api_keys)
      end

      it 'returns user data' do
        data = last_response.json
        expect(data).not_to be_nil
        expect(data.include?("users")).to eq(true)
        expect(data["users"].map { |s| s['id'] }).to eq([user0.username])
      end
    end

    context 'when not authorized' do
      let(:different_user) { create(:user) }
      let(:credentials) { {api_id: different_user.api_id, api_key: different_user.api_key} }

      it 'returns an unauthorized error' do
        get("/users/#{user0.username}", credentials)
        expect(last_response.status).to eq(403)
        data = last_response.json
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthorized")
      end
    end
  end

  describe 'GET /cameras?user_id=#{user0.username}' do
    let!(:user0) { create(:user) }
    let!(:access_token) { create(:access_token, user: user0) }
    let!(:camera0) { create(:camera, owner: user0, is_public: true) }
    let!(:camera1) { create(:camera, owner: user0, is_public: false) }
    let(:access_right) { create(:camera_access_right, token: access_token, right: AccessRight::LIST) }
    let!(:share) { create(:private_camera_share, user: user0, camera: access_right.camera) }
    let(:api_keys) { {api_id: user0.api_id, api_key: user0.api_key} }

    context 'when the user does not exist' do
      it 'returns a NOT FOUND status' do
        expect(get("/cameras?user_id=xxxx", api_keys).status).to eq(404)
      end
    end

    context 'when the user does exist' do
      it 'returns an OK status' do
        expect(get("/cameras?user_id="\
          "#{user0.username}", api_keys).status).to eq(200)
      end
    end

    context 'with no authentication information' do
      before(:each) { get("/public/cameras?user_id=#{user0.username}") }

      it 'only returns public cameras' do
        content = last_response.json
        expect(content).not_to be_nil
        expect(content.include?("cameras")).to eq(true)
        content["cameras"].each do |cam|
          expect(cam).to have_keys(
           'id', 'name', 'owner', 'vendor_id', 'vendor_name', 'model_id', 'model_name',
           'created_at', 'updated_at', 'last_polled_at', 'last_online_at',
           'timezone', 'is_public', 'is_online', 'discoverable', 'location')
          expect(cam).to not_have_keys('owned', 'external', 'internal', 'snapshots',
                                     'auth', 'mac_address', 'rights')
        end
      end
    end

    context 'when the authenticated user is the owner' do
      context 'when include_shared is not set' do
        before(:each) { get("/cameras?user_id=#{user0.username}",
                      { include_shared: false }.merge(api_keys)) }

        it 'only returns public and private cameras' do
          cameras = last_response.json['cameras']
          expect(cameras.map { |s| s['id'] }).to include(camera1.exid, camera0.exid)
          cameras.each do |cam|
            expect(cam['owned']).to eq(true)
            expect(cam).to have_keys(
             'id', 'name', 'owned', 'owner', 'vendor_id', 'vendor_name', 'model_id', 'model_name',
             'created_at', 'updated_at', 'last_polled_at', 'last_online_at',
             'timezone', 'is_public', 'is_online', 'discoverable', 'location',
             'external', 'internal', 'rights')
          end
        end
      end

      context 'when include_shared is set to true' do
        before(:each) do
          get("/cameras?user_id=#{user0.username}",
              { include_shared: true }.merge(api_keys))
        end

        it 'returns shared and owned cameras for the user' do
          cameras = last_response.json['cameras']
          expect(cameras.map { |s| s['id'] }).to include(camera1.exid, camera0.exid, share.camera.exid)
          cameras.each do |cam|
            expect(cam['owned']).to eq(true) if cam['id'] != share.camera.exid
            expect(cam['owned']).to eq(false) if cam['id'] == share.camera.exid
          end
        end
      end
    end
  end

  describe 'DELETE /users/:id' do
    let!(:user0) { create(:user, username: 'xxxx', password: 'yyyy') }
    let(:auth) { env_for(session: { user: user0.id }) }
    let(:api_keys) { {api_id: user0.api_id, api_key: user0.api_key} }

    context 'when the params are valid' do
      it 'deletes the user' do
        skip
        delete("/users/#{user0.username}", api_keys)

        expect(last_response.status).to eq(200)
        expect(::User.by_login(user0.username)).to eq(nil)
      end
    end

    context 'when no valid auth' do
      it 'returns 401' do
        delete("/users/#{user0.username}")
        expect(last_response.status).to eq(401)
      end
    end

    context 'when no auth' do
      it 'returns 401' do
        delete("/users/#{user0.username}")
        expect(last_response.status).to eq(401)
      end
    end

    context 'when the username doesnt exists' do
      it 'returns a 404 not found status' do
        delete('/users/notexistingone', api_keys)
        expect(last_response.status).to eq(404)
      end
    end

    context 'when not authorized' do
      let(:different_user) { create(:user) }
      let(:credentials) { {api_id: different_user.api_id, api_key: different_user.api_key} }

      it 'returns an unauthorized error' do
        get("/users/#{user0.username}", credentials)
        expect(last_response.status).to eq(403)
        data = last_response.json
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthorized")
      end
    end
  end

  describe 'PATCH /users/:id' do
    let!(:user0) { create(:user, username: 'xxxx', password: 'yyyy') }
    let(:api_keys) { {api_id: user0.api_id, api_key: user0.api_key} }

    context 'when no params' do
      before do
        patch("/users/#{user0.username}", api_keys)
      end

      it 'returns a OK status' do
        expect(last_response.status).to eq(200)
      end

      it 'returns same user' do
        expect(last_response.status).to eq(200)
        user = User.by_login(user0.username)
        expect(user.firstname).to eq(user0.firstname)
        expect(user.lastname).to eq(user0.lastname)
        expect(user.email).to eq(user0.email)
        expect(user.country).to eq(user0.country)
      end
    end

    context 'when valid params' do
      before do
        patch("/users/#{user0.username}", patch_params.merge(api_keys))
      end

      it 'returns a OK status' do
        expect(last_response.status).to eq(200)
      end

      it 'updates user in the system' do
        user = User.by_login(user0.username)
        expect(user.firstname).to eq(patch_params[:firstname])
        expect(user.lastname).to eq(patch_params[:lastname])
        expect(user.email).to eq(patch_params[:email])
        expect(user.country.iso3166_a2).to eq(patch_params[:country])
      end

      it 'returns the updated user' do
        expect(last_response.json['users'].map{ |s| s['id'] }).
          to eq([user0.username])
      end
    end

    context 'when blank params' do
      before do
        patch("/users/#{user0.username}", blank_params.merge(api_keys))
      end

      it 'returns a 400 bad request status' do
        expect(last_response.status).to eq(400)
      end
    end

    context 'when no valid auth' do
      it 'returns 401' do
        patch("/users/#{user0.username}", params.merge(api_id: 'blah', api_key: 'blah'))
        expect(last_response.status).to eq(401)
      end
    end

    context 'when no auth' do
      it 'returns 401' do
        patch("/users/#{user0.username}", params)
        expect(last_response.status).to eq(401)
      end
    end

    context 'when the username doesnt exists' do
      it 'returns a 404 not found status' do
        patch('/users/notexistingone', api_keys)
        expect(last_response.status).to eq(404)
      end
    end

    context 'when not authorized' do
      let(:different_user) { create(:user) }
      let(:credentials) { {api_id: different_user.api_id, api_key: different_user.api_key} }

      it 'returns an unauthorized error' do
        patch("/users/#{user0.username}", params.merge(email: 'gh@evercam.io').merge(credentials))
        expect(last_response.status).to eq(403)
        data = last_response.json
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthorized")
      end
    end
  end

  describe 'GET /users/:id/credentials' do
    let(:password) { SecureRandom.base64(6) }
    let(:user) { create(:user, password: password) }
    let(:client) { create(:client) }
    let(:api_keys) { {api_id: client.api_id, api_key: client.api_key} }
    let(:parameters) { {password: password}.merge(api_keys) }

    context 'when properly authenticated' do
      context 'and a valid user name and password are provided' do
        it 'returns success and provides valid user credentials' do
          get("/users/#{user.username}/credentials", parameters)
          expect(last_response.status).to eq(200)
          data = last_response.json
          expect(data).not_to be_nil
          expect(data.include?("api_id")).to eq(true)
          expect(data.include?("api_key")).to eq(true)
          expect(data["api_id"]).to eq(user.api_id)
          expect(data["api_key"]).to eq(user.api_key)
        end
      end

      context 'and a valid email and password are provided' do
        it 'returns success and provides valid user credentials' do
          get("/users/#{user.email}/credentials", parameters)
          expect(last_response.status).to eq(200)
          data = last_response.json
          expect(data).not_to be_nil
          expect(data.include?("api_id")).to eq(true)
          expect(data.include?("api_key")).to eq(true)
          expect(data["api_id"]).to eq(user.api_id)
          expect(data["api_key"]).to eq(user.api_key)
        end
      end

      context 'when a non-existent user name is specified' do
        it 'returns a not found error' do
          get("/users/blah/credentials", parameters)
          expect(last_response.status).to eq(404)
          data = last_response.json
          expect(data).not_to be_nil
          expect(data.include?("message")).to eq(true)
          expect(data["message"]).to eq("No user with an id of blah exists.")
        end
      end

      context 'when a password is not specified' do
        it 'returns a parameters error' do
          parameters.delete(:password)
          get("/users/#{user.username}/credentials", parameters)
          expect(last_response.status).to eq(400)
          data = last_response.json
          expect(data).not_to be_nil
          expect(data.include?("message")).to eq(true)
          expect(data["message"]).to eq("Invalid parameters specified for request.")
          expect(data["context"]).to eq(["password"])
        end
      end

      context 'when an invalid password is specified' do
        it 'returns an authentication error' do
          parameters[:password] = 'this is wrong'
          get("/users/#{user.username}/credentials", parameters)
          expect(last_response.status).to eq(401)
          data = last_response.json
          expect(data).not_to be_nil
          expect(data.include?("message")).to eq(true)
          expect(data["message"]).to eq("Invalid user name and/or password.")
        end
      end
    end
  end
end
