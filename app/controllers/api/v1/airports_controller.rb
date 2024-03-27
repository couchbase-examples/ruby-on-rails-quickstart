# frozen_string_literal: true

module Api
  module V1
    class AirportsController < ApplicationController
      skip_before_action :verify_authenticity_token, only: [:create, :update, :destroy]
      before_action :set_airport, only: [:show, :update, :destroy]

      # GET /api/v1/airports/{id}
      def show
        if @airport
          render json: @airport, status: :ok
        else
          render json: { message: 'Airport not found' }, status: :not_found
        end
      rescue Couchbase::Error::DocumentNotFound => e
        render json: { error: "Airport with ID #{params[:id]} not found", message: e.message }, status: :not_found
      rescue StandardError => e
        render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
      end

      # POST /api/v1/airports/{id}
      def create
        @airport = Airport.create(params[:id], airport_params)
        if @airport
          render json: @airport, status: :created
        else
          render json: { message: 'Airport already exists' }, status: :conflict
        end
      rescue Couchbase::Error::DocumentExists => e
        render json: { error: "Airport with ID #{params[:id]} already exists", message: e.message }, status: :conflict
      rescue StandardError => e
        render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
      end

      # PUT /api/v1/airports/{id}
      def update
        begin
          @airport = Airport.new(airport_params).update(params[:id], airport_params)
          render json: @airport, status: :ok
        rescue ArgumentError => e
          render json: { error: 'Invalid request', message: e.message }, status: :bad_request
        rescue StandardError => e
          render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
        end
      end

      # DELETE /api/v1/airports/{id}
      def destroy
        if @airport
          if @airport.destroy(params[:id])
            render json: { message: 'Airport deleted successfully' }, status: :accepted
          else
            render json: { message: 'Failed to delete airport' }, status: :bad_request
          end
        else
          render json: { message: 'Airport not found' }, status: :not_found
        end
      rescue Couchbase::Error::DocumentNotFound => e
        render json: { error: "Airport with ID #{params[:id]} not found", message: e.message }, status: :not_found
      rescue StandardError => e
        render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
      end

      # GET /api/v1/airports/direct-connections
      def direct_connections
        destination_airport_code = params[:destinationAirportCode]
        limit = params[:limit] || 10
        offset = params[:offset] || 0

        if destination_airport_code.blank?
          render json: { message: 'Destination airport code is required' }, status: :bad_request
        else
          @connections = Airport.direct_connections(destination_airport_code, limit, offset)
          render json: @connections, status: :ok
        end
      rescue StandardError => e
        render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
      end

      private

      def set_airport
        @airport = Airport.find(params[:id])
      rescue Couchbase::Error::DocumentNotFound
        @airport = nil
      end

      def airport_params
        params.require(:airport).permit(:airportname, :city, :country, :faa, :icao, :tz, geo: [:alt, :lat, :lon])
      end
    end
  end
end
