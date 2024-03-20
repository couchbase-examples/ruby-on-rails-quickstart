# frozen_string_literal: true

module Api
  module V1
    # Controller for managing airports
    class AirportsController < ApplicationController
      before_action :set_airport, only: [:show, :update, :destroy]

      # GET /api/v1/airports/{id}
      def show
        if @airport
          render json: @airport, status: :ok
        else
          render json: { error: 'Airport not found' }, status: :not_found
        end
      end

      # POST /api/v1/airports/{id}
      def create
        @airport = Airport.create(airport_params)
        if @airport
          render json: @airport, status: :created
        else
          render json: { error: @airport.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/airports/{id}
      def update
        if @airport.update(airport_params)
          render json: @airport, status: :ok
        else
          render json: { error: @airport.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/airports/{id}
      def destroy
        if @airport.destroy
          render json: { message: 'Airport deleted successfully' }, status: :accepted
        else
          render json: { error: 'Airport not found' }, status: :not_found
        end
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
      end

      private

      def set_airport
        @airport = Airport.find(params[:id])
      end

      def airport_params
        params.require(:airport).permit(:id, :type, :airportname, :city, :country, :faa, :icao, :tz, geo: [:alt, :lat, :lon])
      end
    end
  end
end
