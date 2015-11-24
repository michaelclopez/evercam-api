require_relative '../presenters/log_presenter'

module Evercam
  class V1LogRoutes < Grape::API

    include WebErrors

    DEFAULT_LIMIT = 50

    resource :cameras do
      before do
        authorize!
      end

      desc 'Returns list of logs for given camera'
      params do
        requires :id, type: String, desc: "Unique identifier for the camera"
        optional :from, type: Integer, desc: "From Unix timestamp."
        optional :to, type: Integer, desc: "To Unix timestamp."
        optional :limit, type: Integer, desc: "Number of results per page. Defaults to #{DEFAULT_LIMIT}."
        optional :page, type: Integer, desc: "Page number, starting from 0"
        optional :types, type: String, desc: "Comma separated list of log types: created, accessed, edited, viewed, captured", default: ''
        optional :objects, type: 'Boolean', desc: "Return objects instead of strings", default: false
      end
      get '/:id/logs' do
        params[:id].downcase!
        camera = get_cam(params[:id])
        if params[:from].present? and params[:to].present? and params[:from].to_i > params[:to].to_i
          raise(BadRequestError, "From can't be higher than to")
        end
        from = Time.at(params[:from].to_i).to_s || 0
        to = Time.at(params[:to].to_i).to_s
        to = Time.now.to_s if params[:to].blank?
        limit = params[:limit] || DEFAULT_LIMIT
        page = params[:page] || 0
        page = 0 if page < 0
        limit = DEFAULT_LIMIT if limit < 1
        types = params[:types].split(',').map(&:strip)
        results = CameraActivity.where(camera_id: camera.id).filter(:done_at => (from..to)).reverse_order(:done_at)
        results = results.where(:action => types) unless types.blank?
        total_pages = results.count / limit
        results = results.limit(limit, page * limit).all

        if params[:objects]
          present(Array(results), with: Presenters::Log).merge!({
              :camera_exid => camera.exid,
              :camera_name => camera.name,
              :pages => total_pages
            })
        else
          {
            logs: results,
            pages: total_pages
          }
        end
      end
    end
  end
end

