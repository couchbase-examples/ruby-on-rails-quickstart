# frozen_string_literal: true

module Api
    module V1
        class HotelsController < ApplicationController
            skip_before_action :verify_authenticity_token, only: %i[search filter]
            before_action :validate_query_params, only: [:search]
            # GET /api/v1/hotels/autocomplete
            def search
                @hotels = HotelSearch.search_name(params[:name])
                render json: @hotels, status: :ok
            rescue StandardError => e
                render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
            end

            # GET /api/v1/hotels/filter
            def filter
                @hotels = HotelSearch.filter(HotelSearch.new(
                  {
                    "name"=> hotel_search_params[:name],
                    "title" => hotel_search_params[:title],
                    "description" => hotel_search_params[:description],
                    "country" => hotel_search_params[:country],
                    "city" => hotel_search_params[:city],
                    "state" => hotel_search_params[:state]
                  }
                ), hotel_search_params[:offset],  hotel_search_params[:limit])
                render json: @hotels, status: :ok
            rescue StandardError => e
                render json: { error: 'Internal server error', message: e.message }, status: :internal_server_error
            end

            def hotel_search_params
                params.require(:hotel).permit(:name, :title, :description, :country, :city, :state, :offset, :limit)
            end

            def validate_query_params
                unless params[:name].present?
                    render json: { error: "name query parameter is required" }, status: :bad_request
                end
            end
        end
    end
end

