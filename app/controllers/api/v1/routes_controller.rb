# frozen_string_literal: true

module Api
  module V1
    class RoutesController < ApplicationController
      skip_before_action :verify_authenticity_token, only: [:create, :update, :destroy]
      before_action :set_route, only: [:show, :update, :destroy]

      # GET /api/v1/routes/{id}
      def show
        if @route
          render json: @route, status: :ok
        else
          render json: { message: 'Route not found' }, status: :not_found
        end
      end

      # POST /api/v1/routes/{id}
      def create
        @route = Route.create(params[:id], route_params)
        if @route
          render json: @route, status: :created
        else
          render json: { message: 'Route already exists' }, status: :conflict
        end
      rescue Couchbase::Error::DocumentExists => e
        render json: { error: 'Route already exists', message: e.message }, status: :conflict
      rescue StandardError => e
        render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
      end

      # PUT /api/v1/routes/{id}
      def update
        if @route
          if @route.update(params[:id], route_params)
            render json: @route, status: :ok
          else
            render json: { message: 'Failed to update route' }, status: :unprocessable_entity
          end
        else
          render json: { message: 'Route not found' }, status: :not_found
        end
      rescue Couchbase::Error::DocumentNotFound => e
        render json: { error: 'Route not found', message: e.message }, status: :not_found
      rescue StandardError => e
        render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
      end

      # DELETE /api/v1/routes/{id}
      def destroy
        if @route
          if @route.destroy(params[:id])
            render json: { message: 'Route deleted successfully' }, status: :accepted
          else
            render json: { message: 'Failed to delete route' }, status: :unprocessable_entity
          end
        else
          render json: { message: 'Route not found' }, status: :not_found
        end
      rescue Couchbase::Error::DocumentNotFound => e
        render json: { error: 'Route not found', message: e.message }, status: :not_found
      rescue StandardError => e
        render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
      end

      private

      def set_route
        @route = Route.find(params[:id])
      rescue Couchbase::Error::DocumentNotFound
        @route = nil
      end

      def route_params
        params.require(:route).permit(
          :id, :type, :airline, :airlineid, :sourceairport,
          :destinationairport, :stops, :equipment, :distance,
          schedule: [:day, :flight, :utc]
        )
      end
    end
  end
end
