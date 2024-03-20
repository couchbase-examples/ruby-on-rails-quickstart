# frozen_string_literal: true

module Api
  module V1
    # Controller for managing airlines
    class AirlinesController < ApplicationController
      before_action :set_airline, only: %i[show update destroy]

      # GET /api/v1/airlines/{id}
      def show
        if @airline
          render json: @airline, status: :ok
        else
          render json: { error: 'Airline not found' }, status: :not_found
        end
      end

      # POST /api/v1/airlines/{id}
      def create
        @airline = Airline.create(airline_params)
        if @airline
          render json: @airline, status: :created
        else
          render json: { error: @airline.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/airlines/{id}
      def update
        if @airline.update(airline_params)
          render json: @airline, status: :ok
        else
          render json: { error: @airline.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/airlines/{id}
      def destroy
        if @airline.destroy
          render json: { message: 'Airline deleted successfully' }, status: :accepted
        else
          render json: { error: 'Airline not found' }, status: :not_found
        end
      end

      # GET /api/v1/airlines/list
      def index
        country = params[:country] || ''
        limit = params[:limit] || 10
        offset = params[:offset] || 0

        @airlines = Airline.all(country, limit, offset)

        if @airlines.empty?
          render json: { message: 'No airlines found' }, status: :ok
        else
          render json: @airlines, status: :ok
        end
      end

      # GET /api/v1/airlines/to-airport
      def to_airport
        destination_airport_code = params[:destinationAirportCode] || ''
        limit = params[:limit] || 10
        offset = params[:offset] || 0

        @airlines = Airline.to_airport(destination_airport_code, limit, offset)
        render json: @airlines, status: :ok
      end

      private

      def set_airline
        @airline = Airline.find(params[:id])
      end

      def airline_params
        params.require(:airline).permit(:name, :iata, :icao, :callsign, :country)
      end
    end
  end
end
