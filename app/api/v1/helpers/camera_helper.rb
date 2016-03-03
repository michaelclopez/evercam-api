module Evercam
  module CameraHelper
    # This method searches the list of cameras owned by a user to find a match
    # based on the cameras MAC address. If a match is not found then the
    # method next searches the list of cameras shared with the user. Finally,
    # if no match is found, the method returns nil.
    def camera_for_mac(user, mac_address)
      camera = Camera.where(mac_address: mac_address, owner: user).first
      if camera.nil?
        camera = CameraShare
                 .join(:cameras, :camera_id)
                 .where(camera_shares__sharer_id: user.id, cameras__mac_address: mac_address)
                 .first
      end
      camera
    end

    def get_cam(exid)
      Camera.by_exid!(exid)
    end

    def rtsp_url_for_camera(camera)
      port = camera.config['external_rtsp_port']
      port = "554" if port == ""
      port = ":" + port.to_s
      h264_url = camera.res_url('h264')
      ext_url = camera.config['external_host']
      unless h264_url.blank? or ext_url.blank?
        "rtsp://#{camera.cam_username}:#{camera.cam_password}@#{ext_url}#{port}#{h264_url}"
      else
        nil
      end
    end

    def hls_url_for_camera(camera)
      rtsp_url = rtsp_url_for_camera(camera)
      token = "#{camera.cam_username}|#{camera.cam_password}|#{rtsp_url}|"
      token = encrypt(token) unless rtsp_url.blank?
      Evercam::Config[:streams][:hls_path] + "/live/" + token + "/index.m3u8?camera_id=" + camera.exid unless rtsp_url.blank?
    end

    def rtmp_url_for_camera(camera)
      rtsp_url = rtsp_url_for_camera(camera)
      token = "#{camera.cam_username}|#{camera.cam_password}|#{rtsp_url}|"
      token = encrypt(token) unless rtsp_url.blank?
      Evercam::Config[:streams][:rtmp_path] + "/live/" + token + "?camera_id=" + camera.exid unless rtsp_url.blank?
    end

    def encrypt(message)
      require 'openssl'

      cipher = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
      cipher.encrypt
      cipher.key = "#{Evercam::Config[:snapshots][:key]}"
      cipher.iv = "#{Evercam::Config[:snapshots][:iv]}"
      cipher.padding = 0

      message << ' ' until message.length % 16 == 0
      token = cipher.update(message)
      token << cipher.final

      Base64.urlsafe_encode64(token)
    end

    def auto_generate_camera_id(camera_name)
      camera_name = camera_name.delete("^a-zA-Z0-9").downcase
      chars = [('a'..'z'), (0..9)].flat_map { |i| i.to_a }
      random_string = (0...3).map { chars[rand(chars.length)] }.join
      "#{camera_name[0..5]}-#{random_string}"
    end

    def generate_rights_list(permissions)
      rights = [AccessRight::LIST, AccessRight::SNAPSHOT]
      if permissions == "full"
        AccessRight::BASE_RIGHTS.each do |right|
          if right != AccessRight::DELETE
            rights << right if !rights.include?(right)
            rights << "#{AccessRight::GRANT}~#{right}"
          end
        end
      end
      rights
    end
  end
end
