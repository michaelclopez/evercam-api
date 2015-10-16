require_relative './presenter'

module Evercam
  module Presenters
    class CameraShare < Presenter
      root :shares

      expose :id, documentation: {
        type: 'integer',
        desc: 'Unique identifier for a camera share.',
        required: true
      }

      expose :camera_id, documentation: {
        type: 'string',
        desc: 'Unique identifier of the shared camera.',
        required: true
      } do |s, o|
        s.camera.exid
      end

      expose :sharer_id, documentation: {
        type: 'string',
        desc: 'The unique identifier of the user who shared the camera.',
        required: true
      } do |s,_o|
        s.sharer ? s.sharer.username : nil
      end

      expose :sharer_name, documentation: {
        type: 'string',
        desc: 'Full name of the user the camera is shared with.',
        required: true
      } do |s, _o|
        s.sharer ? s.sharer.fullname : nil
      end

      expose :user_id, documentation: {
        type: 'string',
        desc: 'Unique user id of the user the camera is shared with.',
        required: true
      } do |s, _o|
        s.user.username
      end

      expose :fullname, documentation: {
        type: 'string',
        desc: 'Full name of the user the camera is shared with.',
        required: true
      } do |s, _o|
        s.user.fullname
      end

      expose :email, documentation: {
        type: 'string',
        desc: 'Email of the user the camera is shared with.',
        required: true
      } do |s, o|
        s.user.email
      end

      expose :kind, documentation: {
        type: 'string',
        desc: "Either 'public' or 'private' depending on the share kind.",
        required: true
      }

      expose :rights, documentation: {
        type: 'string',
        desc: "A comma separated list of the rights available on the share.",
        required: true
      } do |s, _o|
        list = []
        if s.kind == 'private'
          rights = AccessRightSet.for(s.camera, s.user)
          list << "Snapshot" if rights.allow?(AccessRight::SNAPSHOT)
          list << "View" if rights.allow?(AccessRight::VIEW)
          list << "Edit" if rights.allow?(AccessRight::EDIT)
          list << "Delete" if rights.allow?(AccessRight::DELETE)
          list << "List" if rights.allow?(AccessRight::LIST)
        else
          list = ["Snapshot", "List"]
        end
        list.join(",")
      end
    end
  end
end