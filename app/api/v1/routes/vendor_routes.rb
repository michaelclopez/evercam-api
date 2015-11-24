require_relative '../presenters/vendor_presenter'

module Evercam
  class V1VendorRoutes < Grape::API

    include WebErrors

    resource :vendors do

      #---------------------------------------------------------------------------
      # GET /v1/vendors
      #---------------------------------------------------------------------------
      desc 'Returns all known IP hardware vendors', {
        entity: Evercam::Presenters::Vendor
      }
      params do
        optional :name, type: String, desc: "Name of the vendor (partial search)"
        optional :mac, type: String, desc: "Mac address of camera"
      end
      get do
        vendors = ::Vendor.eager(:vendor_models)
        vendors = vendors.where(exid: params[:id]) unless params.fetch(:id, nil).nil?
        vendors = vendors.where(Sequel.ilike(:name, "%#{params[:name]}%")) unless params.fetch(:name, nil).nil?
        vendors = vendors.where(%("known_macs" @> ARRAY[?]), params[:mac].upcase[0, 8]) unless params.fetch(:mac, nil).nil?
        present vendors.all, with: Presenters::Vendor, supported: true
      end

      #---------------------------------------------------------------------------
      # GET /v1/vendors/:id
      #---------------------------------------------------------------------------
      desc 'Returns available information for the specified vendor', {
        entity: Evercam::Presenters::Vendor
      }
      params do
        requires :id, type: String, desc: "Unique identifier for the vendor"
      end
      get ':id' do
        params[:id].downcase!
        vendor = Vendor.where(exid: params[:id]).first
        raise Evercam::NotFoundError.new("Unable to locate the '#{params[:id]}' vendor.",
                                         "vendor_not_found_error", params[:id]) if vendor.blank?
        present [vendor], with: Presenters::Vendor, supported: true
      end

      before do
        authorize!
      end

      #---------------------------------------------------------------------------
      # POST /v1/vendors
      #---------------------------------------------------------------------------
      desc 'Create a new vendor', {
        entity: Evercam::Presenters::Vendor
      }
      params do
        requires :id, type: String, desc: "Unique identifier for the vendor"
        requires :name, type: String, desc: "vendor name"
        optional :macs, type: String, desc: "Comma separated list of MAC's prefixes the vendor uses"
      end
      post do
        params[:id].downcase!
        known_macs = ['']
        if params.include?(:macs) && params[:macs]
          known_macs = params[:macs].split(",").inject([]) { |list, entry| list << entry.strip }
        end
        outcome = Actors::VendorCreate.run(params.merge!(:known_macs => known_macs))
        unless outcome.success?
          raise OutcomeError, outcome.to_json
        end
        # Adding default vendor_model
        parameters = {
          id: "#{outcome.result.exid}_default",
          vendor_id: outcome.result.exid,
          name: 'Default'
        }
        Actors::ModelCreate.run(parameters)

        present Array(outcome.result), with: Presenters::Vendor, supported: true
      end

      #---------------------------------------------------------------------------
      # PATCH /v1/vendors/:id
      #---------------------------------------------------------------------------
      desc 'Updates full or partial data on your existing vendor', {
        entity: Evercam::Presenters::Vendor
      }
      params do
        requires :id, type: String, desc: "Unique identifier for the vendor"
        optional :name, type: String, desc: "vendor name"
        optional :macs, type: String, desc: "Comma separated list of MAC's prefixes the vendor uses"
      end
      patch '/:id' do
        params[:id].downcase!
        known_macs = ['']
        if params.include?(:macs) && params[:macs]
          known_macs = params[:macs].split(",").inject([]) { |list, entry| list << entry.strip }
        end
        outcome = Actors::VendorUpdate.run(params.merge!(:known_macs => known_macs))
        unless outcome.success?
          raise OutcomeError, outcome.to_json
        end
        present Array(outcome.result), with: Presenters::Vendor, supported: true
      end

    end
  end
end

