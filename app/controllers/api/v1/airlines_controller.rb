# frozen_string_literal: true

module Api
  module V1
    class AirlinesController < ApplicationController
      skip_before_action :verify_authenticity_token, only: [:create, :update, :destroy]
      before_action :set_airline, only: [:show, :update, :destroy]

      # GET /api/v1/airlines/{id}
      def show
        if @airline
          render json: @airline, status: :ok
        else
          render json: { message: 'Airline not found' }, status: :not_found
        end
      end

      # POST /api/v1/airlines/{id}
      def create
        @airline = Airline.create(params[:id], airline_params)
        if @airline
          render json: @airline, status: :created
        else
          render json: { message: 'Airline already exists' }, status: :conflict
        end
      rescue Couchbase::Error::DocumentExists => e
        render json: { error: 'Airline already exists', message: e.message }, status: :conflict
      rescue StandardError => e
        render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
      end

      # PUT /api/v1/airlines/{id}
      def update
        if @airline
          if @airline.update(params[:id], airline_params)
            render json: @airline, status: :ok
          else
            render json: { message: 'Failed to update airline' }, status: :unprocessable_entity
          end
        else
          render json: { message: 'Airline not found' }, status: :not_found
        end
      rescue Couchbase::Error::DocumentNotFound => e
        render json: { error: 'Airline not found', message: e.message }, status: :not_found
      rescue StandardError => e
        render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
      end

      # DELETE /api/v1/airlines/{id}
      def destroy
        if @airline
          if @airline.destroy(params[:id])
            render json: { message: 'Airline deleted successfully' }, status: :accepted
          else
            render json: { message: 'Failed to delete airline' }, status: :unprocessable_entity
          end
        else
          render json: { message: 'Airline not found' }, status: :not_found
        end
      rescue Couchbase::Error::DocumentNotFound => e
        render json: { error: 'Airline not found', message: e.message }, status: :not_found
      rescue StandardError => e
        render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
      end

      # GET /api/v1/airlines/list
      def index
        country = params[:country]
        limit = params[:limit] || 10
        offset = params[:offset] || 0

        @airlines = Airline.all(country, limit, offset)

        if @airlines.empty?
          render json: { message: 'No airlines found' }, status: :ok
        else
          render json: @airlines, status: :ok
        end
      rescue StandardError => e
        render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
      end

      # GET /api/v1/airlines/to-airport
      def to_airport
        destination_airport_code = params[:destinationAirportCode]
        limit = params[:limit] || 10
        offset = params[:offset] || 0

        if destination_airport_code.blank?
          render json: { message: 'Destination airport code is required' }, status: :bad_request
        else
          @airlines = Airline.to_airport(destination_airport_code, limit, offset)
          render json: @airlines, status: :ok
        end
      rescue StandardError => e
        render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
      end

      private

      def set_airline
        @airline = Airline.find(params[:id])
      rescue Couchbase::Error::DocumentNotFound
        @airline = nil
      end

      def airline_params
        params.require(:airline).permit(:callsign, :country, :iata, :icao, :id, :name, :type)
      end
    end
  end
end
