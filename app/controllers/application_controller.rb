# frozen_string_literal: true

# Maps errors raised by API actions to JSON responses in one place.
class ApplicationController < ActionController::API
  # Rails checks rescue_from handlers bottom-up, so declare the generic
  # handler first and the more specific ones after it.
  rescue_from StandardError, with: :handle_internal_error
  rescue_from CouchbaseConnection::CouchbaseUnavailableError, with: :handle_database_unavailable

  private

  def handle_internal_error(exception)
    render json: { error: 'Internal server error', message: exception.message }, status: :internal_server_error
  end

  def handle_database_unavailable(_exception)
    render json: {
      error: 'Service Unavailable',
      message: 'Database connection is not available. Please check configuration or try again later.'
    }, status: :service_unavailable
  end
end
