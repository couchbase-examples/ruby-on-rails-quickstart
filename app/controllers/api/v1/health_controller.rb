# frozen_string_literal: true

module Api
  module V1
    class HealthController < ApplicationController
      def show
        health_status = {
          status: 'healthy',
          timestamp: Time.current.iso8601,
          services: {
            couchbase: check_couchbase
          }
        }

        all_up = health_status[:services].values.all? { |s| s[:status] == 'up' }
        status_code = all_up ? :ok : :service_unavailable

        render json: health_status, status: status_code
      end

      private

      def check_couchbase
        if defined?(COUCHBASE_CLUSTER) && COUCHBASE_CLUSTER
          # Perform simple bucket check to verify connection
          COUCHBASE_CLUSTER.bucket('travel-sample')
          { status: 'up', message: 'Connected to travel-sample bucket' }
        else
          { status: 'down', message: 'Couchbase not initialized' }
        end
      rescue StandardError => e
        { status: 'down', message: e.message }
      end
    end
  end
end
