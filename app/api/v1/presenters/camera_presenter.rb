require_relative './presenter'

module Evercam
  module Presenters
    class Camera < Presenter
      include CameraHelper

      root :cameras

      expose :id, documentation: {
        type: 'string',
        desc: 'Unique Evercam identifier for the camera',
        required: true
      } do |s,o|
        s.exid
      end

      expose :name, documentation: {
        type: 'string',
        desc: 'Human readable or friendly name for the camera',
        required: true
      }

      expose :owned, if: lambda {|instance, options| !options[:user].nil? },
             documentation: {
               type: 'Boolean',
               desc: 'True if the user owns the camera, false otherwise'
             } do |c,o|
        (c.owner.id == o[:user].id)
      end

      expose :owner, documentation: {
        type: 'string',
        desc: 'Username of camera owner',
        required: true
      } do |s,o|
        s.owner.username
      end

      expose :vendor_id, documentation: {
        type: 'string',
        desc: 'Unique identifier for the camera vendor'
      } do |c,o|
        nil == c.vendor_model ? "" : c.vendor_model.vendor.exid
      end

      expose :vendor_name, documentation: {
        type: 'string',
        desc: 'The name for the camera vendor'
      } do |c,o|
        nil == c.vendor ? "" : c.vendor.name
      end

      expose :model_id, documentation: {
        type: 'string',
        desc: 'Unique identifier for the camera model'
      } do |c,o|
        nil == c.vendor_model ? "" : c.vendor_model.exid
      end

      expose :model_name, documentation: {
        type: 'string',
        desc: 'Name of the camera model'
      } do |c,o|
        nil == c.vendor_model ? "" : c.vendor_model.name
      end

      with_options(format_with: :timestamp) do

        expose :created_at, documentation: {
          type: 'integer',
          desc: 'Unix timestamp at creation',
          required: true
        }

        expose :updated_at, documentation: {
          type: 'integer',
          desc: 'Unix timestamp at last update',
          required: true
        }

        expose :last_polled_at, documentation: {
          type: 'integer',
          desc: 'Unix timestamp at last heartbeat poll'
        }

        expose :last_online_at, documentation: {
          type: 'integer',
          desc: 'Unix timestamp of the last successful heartbeat of the camera'
        }

      end

      expose :timezone, documentation: {
        type: 'string',
        desc: 'Name of the <a href="http://en.wikipedia.org/wiki/List_of_tz_database_time_zones">IANA/tz</a> timezone where this camera is located',
        required: true
      } do |s,o|
        s.timezone.zone
      end

      expose :is_online_email_owner_notification, documentation: {
        type: 'boolean',
        desc: 'Whether or not to send online/offline notifications to camera owner.'
      }

      expose :is_online, documentation: {
        type: 'boolean',
        desc: 'Whether or not this camera is currently online'
      }

      expose :is_public, documentation: {
        type: 'boolean',
        desc: 'Whether or not this camera is publically available',
        required: true
      }

      expose :discoverable, documentation: {
          type: 'boolean',
          desc: 'Whether the camera is publicly findable'
      } do |c,o|
        c.discoverable?
      end

      expose :cam_username, if: lambda {|instance, options| !options[:minimal]},
             documentation: {
                 type: 'String',
                 desc: 'Camera username'
             } do |c,o|
        c.cam_username
      end

      expose :cam_password, if: lambda {|instance, options| !options[:minimal]},
             documentation: {
                 type: 'String',
                 desc: 'Camera password'
             } do |c,o|
        c.cam_password
      end

      expose :mac_address, if: lambda {|instance, options| !options[:minimal]},
             documentation: {
                 type: 'string',
                 desc: 'The physical network MAC address of the camera'
             } do |c,_|
        c.mac_address.to_s
      end

      expose :location, documentation: {
          type: 'hash',
          desc: 'GPS lng and lat coordinates of the camera location'
      } do |c,o|
        if c.location
          { lat: c.location.y, lng: c.location.x }
        else
          { lat: 0, lng: 0 }
        end
      end

      expose :external, if: lambda {|instance, options| !options[:minimal]} do

        expose :host, documentation: {
                   type: 'String',
                   desc: 'External host of the camera'
               } do |c,o|
          c.config['external_host'].to_s
        end

        expose :http do

          expose :port, documentation: {
                     type: 'Integer',
                     desc: 'External http port of the camera'
                 } do |c,o|
            c.config['external_http_port']
          end

          expose :camera, documentation: {
              type: 'String',
              desc: 'External camera url'
          } do |c,o|
            c.external_url.to_s
          end

          expose :jpg, documentation: {
              type: 'String',
              desc: 'External snapshot url'
          } do |c,o|
            host = c.external_url
            (c.res_url('jpg').blank? or host.blank?) ? "" : host << c.res_url('jpg')
          end

          expose :mjpg, documentation: {
            type: 'String',
            desc: 'External mjpg url.'
          } do |c,o|
            host = c.external_url
            (c.res_url('mjpg').blank? or host.blank?) ? "" : host << c.res_url('mjpg')
          end

        end

        expose :rtsp do

          expose :port, documentation: {
                     type: 'Integer',
                     desc: 'External rtsp port of the camera'
                 } do |c,o|
            c.config['external_rtsp_port']
          end

          expose :mpeg, documentation: {
              type: 'String',
              desc: 'External mpeg url'
          } do |c,o|
            host = c.external_url('rtsp')
            (c.res_url('mpeg').blank? or c.config['external_rtsp_port'] == 0 or host.blank?) ? "" : host << c.res_url('mpeg')
          end

          expose :audio, documentation: {
              type: 'String',
              desc: 'External audio url'
          } do |c,o|
            host = c.external_url('rtsp')
            (c.res_url('audio').blank? or c.config['external_rtsp_port'] == 0 or host.blank?) ? "" : host << c.res_url('audio')
          end

          expose :h264, documentation: {
              type: 'String',
              desc: 'External h264 url'
          } do |c,o|
            host = c.external_url('rtsp')
            (c.res_url('h264').blank? or c.config['external_rtsp_port'] == 0 or host.blank?) ? "" : host << c.res_url('h264')
          end

        end
      end

      expose :internal, if: lambda {|instance, options| !options[:minimal]} do

        expose :host, documentation: {
                   type: 'String',
                   desc: 'Internal host of the camera'
               } do |c,o|
          c.config['internal_host'].to_s
        end

        expose :http do
          expose :port, documentation: {
                     type: 'Integer',
                     desc: 'Internal http port of the camera'
                 } do |c,o|
            c.config['internal_http_port']
          end

          expose :camera, documentation: {
              type: 'String',
              desc: 'Internal camera url'
          } do |c,o|
            c.internal_url.to_s
          end

          expose :jpg, documentation: {
              type: 'String',
              desc: 'Internal snapshot url'
          } do |c,o|
            host = c.internal_url
            (c.res_url('jpg').blank? or host.blank?) ? "" : host << c.res_url('jpg')
          end

          expose :mjpg, documentation: {
              type: 'String',
              desc: 'Internal mjpg url.'
          } do |c,o|
            host = c.internal_url
            (c.res_url('mjpg').blank? or host.blank?) ? "" : host << c.res_url('mjpg')
          end

        end

        expose :rtsp do

          expose :port, documentation: {
                     type: 'Integer',
                     desc: 'Internal rtsp port of the camera'
                 } do |c,o|
            c.config['internal_rtsp_port']
          end

          expose :mpeg, documentation: {
              type: 'String',
              desc: 'External mpeg url'
          } do |c,o|
            host = c.internal_url('rtsp')
            (c.res_url('mpeg').blank? or c.config['internal_rtsp_port'] == 0 or host.blank?) ? "" : host << c.res_url('mpeg')
          end

          expose :audio, documentation: {
              type: 'String',
              desc: 'External audio url'
          } do |c,o|
            host = c.internal_url('rtsp')
            (c.res_url('audio').blank? or c.config['internal_rtsp_port'] == 0 or host.blank?) ? "" : host << c.res_url('audio')
          end

          expose :h264, documentation: {
              type: 'String',
              desc: 'External h264 url'
          } do |c,o|
            host = c.internal_url('rtsp')
            (c.res_url('h264').blank? or c.config['internal_rtsp_port'] == 0 or host.blank?) ? "" : host << c.res_url('h264')
          end

        end
      end

      expose :proxy_url do
        expose :hls, documentation: {
          type: 'String',
          desc: 'HLS url'
        } do |camera, _options|
          camera.is_public ? hls_url_for_camera(camera).to_s : ""
        end

        expose :rtmp, documentation: {
          type: 'String',
          desc: 'RTMP url'
        } do |c,o|
          host = rtmp_url_for_camera(c)
          host.to_s
        end

      end

      expose :rights, if: lambda {|instance, options| !options[:user].nil?},
                      documentation: {
                        type: 'String',
                        desc: 'A comma separated list of the users rights on the camera'
                      } do |camera, options|
        if options[:user].respond_to?('username')
          key = "camera-rights/#{camera.exid}/#{options[:user].username}"
        else
          key = "camera-rights/#{camera.exid}/#{options[:user].name}"
        end
        rights_string = Evercam::Services::dalli_cache.get(key)
        if rights_string.nil?
          list   = []
          grants = []
          if options[:user].respond_to?('username')
            if options[:user] == camera.owner
              AccessRight::BASE_RIGHTS.each do |right|
                list << right
                grants << "#{AccessRight::GRANT}~#{right}"
              end
            else
              options[:tokens] = AccessToken.where(user_id: options[:user].id).all if options[:tokens].nil?
              rights = AccessRight.where(
                token: options[:tokens],
                camera_id: camera.id,
                status: AccessRight::ACTIVE
              ).select(:right).all
              if rights.blank?
                list = ["snapshot,list"]
                grants = []
              else
                rights = rights.map { |right| right.to_s.gsub("::", "") }
                rights.each do |right|
                  list << right
                  grants << right
                end
              end
            end
          else
            rights = AccessRightSet.for(camera, options[:user])
            AccessRight::BASE_RIGHTS.each do |right|
              list << right if rights.allow?(right)
              grants << "#{AccessRight::GRANT}~#{right}" if rights.allow?("#{AccessRight::GRANT}~#{right}")
            end
          end
          list.concat(grants) unless grants.empty?
          rights_string = list.uniq.join(",")
          Evercam::Services::dalli_cache.set(key, rights_string)
        end
        rights_string
      end

      expose :thumbnail_url, documentation: {
               type: 'String',
               desc: 'Latest recorded snapshot url'
             } do |camera, _options|
        if camera.thumbnail_url.blank?
        ""
        else
          if camera.thumbnail_url <=> "s3"
            camera.thumbnail_url
          else
            ""
          end
        end
        #camera.thumbnail_url.blank? ? "" : "" # temprory solution to return empty thumbnail url
      end
    end
  end
end
