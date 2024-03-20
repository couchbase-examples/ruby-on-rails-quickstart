require 'rails_helper'

RSpec.describe 'Airports API', type: :request do
  describe 'GET /api/v1/airports/{id}' do
    let(:airport_id) { 'airport_1262' }

    context 'when the airport exists' do
      let(:expected_airport) do
        {
          'id' => 1262,
          'type' => 'airport',
          'airportname' => 'La Garenne',
          'city' => 'Agen',
          'country' => 'France',
          'faa' => 'AGF',
          'icao' => 'LFBA',
          'tz' => 'Europe/Paris',
          'geo' => {
            'lat' => 44.174721,
            'lon' => 0.590556,
            'alt' => 204
          }
        }
      end

      before do
        allow(AIRPORT_COLLECTION).to receive(:get).with(airport_id).and_return(double(success?: true, content: expected_airport))
      end

      it 'returns the airport' do
        get "/api/v1/airports/#{airport_id}"

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(JSON.parse(response.body)).to eq(expected_airport)
      end
    end

    context 'when the airport does not exist' do
      before do
        allow(AIRPORT_COLLECTION).to receive(:get).with(airport_id).and_raise(Couchbase::Error::DocumentNotFound)
      end

      it 'returns a not found error' do
        get "/api/v1/airports/#{airport_id}"

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Airport not found' })
      end
    end
  end

  describe 'POST /api/v1/airports/{id}' do
    let(:airport_id) { 'airport_post' }
    let(:airport_params) do
      {
        'id' => 999,
        'type' => 'test-airport',
        'airportname' => 'Test Airport',
        'city' => 'Test City',
        'country' => 'Test Country',
        'faa' => '',
        'icao' => 'Test LFAG',
        'tz' => 'Test Europe/Paris',
        'geo' => {
          'lat' => 49.868547,
          'lon' => 3.029578,
          'alt' => 295.0
        }
      }
    end

    context 'when the airport is created successfully' do
      before do
        allow(AIRPORT_COLLECTION).to receive(:insert).with(airport_params).and_return(airport_id)
      end

      it 'returns the created airport' do
        post "/api/v1/airports/#{airport_id}", params: { airport: airport_params }

        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(JSON.parse(response.body)).to include(airport_params)
      end
    end

    context 'when the airport already exists' do
      before do
        allow(AIRPORT_COLLECTION).to receive(:insert).with(airport_params).and_raise(Couchbase::Error::DocumentExistsError)
      end

      it 'returns a conflict error' do
        post "/api/v1/airports/#{airport_id}", params: { airport: airport_params }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Validation failed: Document already exists' })
      end
    end
  end

  describe 'PUT /api/v1/airports/{id}' do
    let(:airport_id) { 'airport_put' }
    let(:airport_params) do
      {
        'id' => 999,
        'type' => 'test-airport',
        'airportname' => 'Test Airport',
        'city' => 'Test City',
        'country' => 'Test Country',
        'faa' => 'BCD',
        'icao' => 'TEST',
        'tz' => 'Test Europe/Paris',
        'geo' => {
          'lat' => 49.868547,
          'lon' => 3.029578,
          'alt' => 295.0
        }
      }
    end

    context 'when the airport is updated successfully' do
      before do
        allow(AIRPORT_COLLECTION).to receive(:upsert).with(airport_id, airport_params)
        allow(Airport).to receive(:find).with(airport_id).and_return(Airport.new(airport_params))
      end

      it 'returns the updated airport' do
        put "/api/v1/airports/#{airport_id}", params: { airport: airport_params }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(JSON.parse(response.body)).to include(airport_params)
      end
    end

    context 'when the airport does not exist' do
      before do
        allow(AIRPORT_COLLECTION).to receive(:upsert).with(airport_id, airport_params).and_raise(Couchbase::Error::DocumentNotFound)
      end

      it 'returns a not found error' do
        put "/api/v1/airports/#{airport_id}", params: { airport: airport_params }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Airport not found' })
      end
    end
  end

  describe 'DELETE /api/v1/airports/{id}' do
    let(:airport_id) { 'airport_delete' }

    context 'when the airport is deleted successfully' do
      before do
        allow(AIRPORT_COLLECTION).to receive(:remove).with(airport_id)
      end

      it 'returns a success message' do
        delete "/api/v1/airports/#{airport_id}"

        expect(response).to have_http_status(:accepted)
        expect(JSON.parse(response.body)).to eq({ 'message' => 'Airport deleted successfully' })
      end
    end

    context 'when the airport does not exist' do
      before do
        allow(AIRPORT_COLLECTION).to receive(:remove).with(airport_id).and_raise(Couchbase::Error::DocumentNotFound)
      end

      it 'returns a not found error' do
        delete "/api/v1/airports/#{airport_id}"

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Airport not found' })
      end
    end
  end

  describe 'GET /api/v1/airports/direct-connections' do
    let(:destination_airport_code) { 'JFK' }
    let(:limit) { 10 }
    let(:offset) { 0 }
    let(:expected_connections) { ['LAX', 'SFO', 'ATL'] }

    context 'when the destination airport code is provided' do
      before do
        allow(Airport).to receive(:direct_connections).with(destination_airport_code, limit, offset).and_return(expected_connections)
      end

      it 'returns the direct connections' do
        get "/api/v1/airports/direct-connections", params: { destinationAirportCode: destination_airport_code, limit: limit, offset: offset }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(JSON.parse(response.body)).to eq(expected_connections)
      end
    end

    context 'when the destination airport code is not provided' do
      it 'returns a bad request error' do
        get "/api/v1/airports/direct-connections"

        expect(response).to have_http_status(:bad_request)
        expect(JSON.parse(response.body)).to eq({ 'message' => 'Destination airport code is required' })
      end
    end
  end
end
