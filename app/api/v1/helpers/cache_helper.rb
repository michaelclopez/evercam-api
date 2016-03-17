module Evercam
  module CacheHelper
    def invalidate_for_user(username)
      ['true', 'false', ''].repeated_permutation(1) do |a|
        Evercam::Services::dalli_cache.delete("cameras|#{username}|#{a[0]}")
      end
    end

    def invalidate_for_camera(camera_exid)
      camera = Camera.by_exid!(camera_exid)
      invalidate_for_user(camera.owner.username)

      CameraShare.where(camera_id: camera.id).each do |camera_share|
        username = User[camera_share.user_id].username
        invalidate_for_user(username)
      end

      Evercam::Services::dalli_cache.delete(camera_exid)
    end
  end
end
