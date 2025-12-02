class ApplicationController < ActionController::API
  rescue_from CouchbaseConnection::CouchbaseUnavailableError, with: :handle_database_unavailable

  private

  def handle_database_unavailable(exception)
    render json: {
      error: 'Service Unavailable',
      message: 'Database connection is not available. Please check configuration or try again later.'
    }, status: :service_unavailable
  end
end
