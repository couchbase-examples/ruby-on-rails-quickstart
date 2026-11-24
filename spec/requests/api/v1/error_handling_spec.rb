# frozen_string_literal: true

require 'rails_helper'

# ApplicationController maps errors to HTTP responses for every API endpoint.
# These examples stub the models, so they do not need a Couchbase cluster.
RSpec.describe 'API error handling', type: :request do
  let(:unavailable) do
    CouchbaseConnection::CouchbaseUnavailableError.new('Couchbase is not initialized.')
  end

  describe 'when Couchbase is unavailable' do
    {
      '/api/v1/airlines/list' => {},
      '/api/v1/airlines/to-airport' => { destinationAirportCode: 'SFO' },
      '/api/v1/airports/direct-connections' => { destinationAirportCode: 'SFO' },
      '/api/v1/hotels/autocomplete' => { name: 'sea' }
    }.each do |path, query|
      it "returns 503 for GET #{path}" do
        allow(Airline).to receive(:all).and_raise(unavailable)
        allow(Airline).to receive(:to_airport).and_raise(unavailable)
        allow(Airport).to receive(:direct_connections).and_raise(unavailable)
        allow(Hotel).to receive(:search_name).and_raise(unavailable)

        get path, params: query

        expect(response).to have_http_status(:service_unavailable)
        expect(JSON.parse(response.body)).to include('error' => 'Service Unavailable')
      end
    end

    it 'returns 503 when creating a document' do
      allow(Airline).to receive(:create).and_raise(unavailable)

      post '/api/v1/airlines/airline_error_handling', params: {
        airline: { name: 'Test', iata: 'TT', icao: 'TST', callsign: 'TEST', country: 'Nowhere' }
      }

      expect(response).to have_http_status(:service_unavailable)
    end
  end

  describe 'when an unexpected error occurs' do
    it 'returns a JSON 500 response' do
      allow(Airline).to receive(:all).and_raise(RuntimeError, 'boom')

      get '/api/v1/airlines/list'

      expect(response).to have_http_status(:internal_server_error)
      expect(JSON.parse(response.body)).to eq('error' => 'Internal server error', 'message' => 'boom')
    end
  end
end
