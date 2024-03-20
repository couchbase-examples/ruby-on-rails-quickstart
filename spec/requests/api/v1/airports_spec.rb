require 'rails_helper'
require 'swagger_helper'

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

describe 'Airports API', type: :request, swagger_doc: 'v1/swagger.json' do
  path '/api/v1/airports/{id}' do
    get 'Retrieves an airport by ID' do
      tags 'Airports'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string, description: 'ID of the airport'

      response '200', 'airport found' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            type: { type: :string },
            airportname: { type: :string },
            city: { type: :string },
            country: { type: :string },
            faa: { type: :string },
            icao: { type: :string },
            tz: { type: :string },
            geo: {
              type: :object,
              properties: {
                alt: { type: :number },
                lat: { type: :number },
                lon: { type: :number }
              }
            }
          },
          required: ['id', 'type', 'airportname', 'city', 'country', 'faa', 'icao', 'tz', 'geo']

        let(:id) { 'airport_1262' }
        run_test!
      end

      response '404', 'airport not found' do
        let(:id) { 'invalid_id' }
        run_test!
      end
    end

    post 'Creates an airport' do
      tags 'Airports'
      consumes 'application/json'
      parameter name: :airport, in: :body, schema: {
        type: :object,
        properties: {
          id: { type: :integer },
          type: { type: :string },
          airportname: { type: :string },
          city: { type: :string },
          country: { type: :string },
          faa: { type: :string },
          icao: { type: :string },
          tz: { type: :string },
          geo: {
            type: :object,
            properties: {
              alt: { type: :number },
              lat: { type: :number },
              lon: { type: :number }
            }
          }
        },
        required: ['id', 'type', 'airportname', 'city', 'country', 'faa', 'icao', 'tz', 'geo']
      }

      response '201', 'airport created' do
        let(:airport) do
          {
            id: 999,
            type: 'test-airport',
            airportname: 'Test Airport',
            city: 'Test City',
            country: 'Test Country',
            faa: '',
            icao: 'Test LFAG',
            tz: 'Test Europe/Paris',
            geo: {
              lat: 49.868547,
              lon: 3.029578,
              alt: 295.0
            }
          }
        end
        run_test!
      end

      response '422', 'invalid request' do
        let(:airport) { { airportname: 'Test Airport' } }
        run_test!
      end
    end

    put 'Updates an airport' do
      tags 'Airports'
      consumes 'application/json'
      parameter name: :id, in: :path, type: :string, description: 'ID of the airport'
      parameter name: :airport, in: :body, schema: {
        type: :object,
        properties: {
          airportname: { type: :string },
          city: { type: :string },
          country: { type: :string },
          faa: { type: :string },
          icao: { type: :string },
          tz: { type: :string },
          geo: {
            type: :object,
            properties: {
              alt: { type: :number },
              lat: { type: :number },
              lon: { type: :number }
            }
          }
        }
      }

      response '200', 'airport updated' do
        let(:id) { 'airport_1262' }
        let(:airport) { { airportname: 'Updated Airport' } }
        run_test!
      end

      response '404', 'airport not found' do
        let(:id) { 'invalid_id' }
        let(:airport) { { airportname: 'Updated Airport' } }
        run_test!
      end
    end

    delete 'Deletes an airport' do
      tags 'Airports'
      parameter name: :id, in: :path, type: :string, description: 'ID of the airport'

      response '204', 'airport deleted' do
        let(:id) { 'airport_1262' }
        run_test!
      end

      response '404', 'airport not found' do
        let(:id) { 'invalid_id' }
        run_test!
      end
    end
  end

  path '/api/v1/airports/direct-connections' do
    get 'Retrieves all direct connections from a target airport' do
      tags 'Airports'
      produces 'application/json'
      parameter name: :destinationAirportCode, in: :query, type: :string, description: 'FAA code of the target airport', required: true
      parameter name: :limit, in: :query, type: :integer, description: 'Maximum number of results to return'
      parameter name: :offset, in: :query, type: :integer, description: 'Number of results to skip for pagination'

      response '200', 'direct connections found' do
        schema type: :array,
          items: {
            type: :string
          }

        let(:destinationAirportCode) { 'LAX' }
        let(:limit) { 10 }
        let(:offset) { 0 }
        run_test!
      end

      response '400', 'bad request' do
        let(:destinationAirportCode) { '' }
        run_test!
      end
    end
  end
end