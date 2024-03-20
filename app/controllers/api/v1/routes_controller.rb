# frozen_string_literal: true

module Api
  module V1
    # Controller for managing routes
    class RoutesController < ApplicationController
      before_action :set_route, only: [:show, :update, :destroy]

      # GET /api/v1/routes/{id}
      def show
        if @route
          render json: @route, status: :ok
        else
          render json: { error: 'Route not found' }, status: :not_found
        end
      end

      # POST /api/v1/routes/{id}
      def create
        @route = Route.create(route_params)
        if @route
          render json: @route, status: :created
        else
          render json: { error: @route.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      end

      # PUT /api/v1/routes/{id}
      def update
        if @route.update(route_params)
          render json: @route, status: :ok
        else
          render json: { error: @route.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/routes/{id}
      def destroy
        if @route.destroy
          render json: { message: 'Route deleted successfully' }, status: :accepted
        else
          render json: { error: 'Route not found' }, status: :not_found
        end
      end

      private

      def set_route
        @route = Route.find(params[:id])
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
