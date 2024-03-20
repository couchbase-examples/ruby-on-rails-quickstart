require 'rails_helper'

RSpec.describe 'Routes API', type: :request do
  describe 'GET /api/v1/routes/{id}' do
    let(:route_id) { 'route_10209' }
    let(:expected_route) do
      {
        'id' => 10209,
        'type' => 'route',
        'airline' => 'AH',
        'airlineid' => 'airline_794',
        'sourceairport' => 'MRS',
        'destinationairport' => 'TLM',
        'stops' => 0,
        'equipment' => '736',
        'schedule' => [
          { 'day' => 0, 'utc' => '22:18:00', 'flight' => 'AH705' },
          { 'day' => 0, 'utc' => '08:47:00', 'flight' => 'AH413' },
          # Add more schedule items as needed
        ],
        'distance' => 1097.2184613947677
      }
    end

    before do
      allow(ROUTE_COLLECTION).to receive(:get).with(route_id).and_return(double(success?: true, content: expected_route))
    end

    it 'returns the route' do
      get "/api/v1/routes/#{route_id}"

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq('application/json; charset=utf-8')
      expect(JSON.parse(response.body)).to eq(expected_route)
    end
  end

  describe 'POST /api/v1/routes/{id}' do
    let(:route_id) { 'route_post' }
    let(:route_params) do
      {
        'id' => 10001,
        'type' => 'route',
        'airline' => 'AF',
        'airlineid' => 'airline_137',
        'sourceairport' => 'TLV',
        'destinationairport' => 'MRS',
        'stops' => 0,
        'equipment' => '320',
        'schedule' => [
          { 'day' => 0, 'utc' => '10:13:00', 'flight' => 'AF198' },
          { 'day' => 0, 'utc' => '19:14:00', 'flight' => 'AF547' }
          # Add more schedule items as needed
        ],
        'distance' => 2881.617376098415
      }
    end

    context 'when the route is created successfully' do
      before do
        allow(ROUTE_COLLECTION).to receive(:insert).with(route_params).and_return(route_id)
      end

      it 'returns the created route' do
        post "/api/v1/routes/#{route_id}", params: { route: route_params }

        expect(response).to have_http_status(:created)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(JSON.parse(response.body)).to include(route_params)
      end
    end

    context 'when the route already exists' do
      before do
        allow(ROUTE_COLLECTION).to receive(:insert).with(route_params).and_raise(Couchbase::Error::DocumentExistsError)
      end

      it 'returns a conflict error' do
        post "/api/v1/routes/#{route_id}", params: { route: route_params }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Validation failed: Document already exists' })
      end
    end
  end

  describe 'PUT /api/v1/routes/{id}' do
    let(:route_id) { 'route_put' }
    let(:route_params) do
      {
        'id' => 9999,
        'type' => 'route',
        'airline' => 'AF',
        'airlineid' => 'airline_137',
        'sourceairport' => 'TLV',
        'destinationairport' => 'MRS',
        'stops' => 0,
        'equipment' => '320',
        'schedule' => [
          { 'day' => 0, 'utc' => '10:13:00', 'flight' => 'AF198' },
          { 'day' => 0, 'utc' => '19:14:00', 'flight' => 'AF547' }
          # Add more schedule items as needed
        ],
        'distance' => 3000
      }
    end

    context 'when the route is updated successfully' do
      before do
        allow(ROUTE_COLLECTION).to receive(:upsert).with(route_id, route_params)
        allow(Route).to receive(:find).with(route_id).and_return(Route.new(route_params))
      end

      it 'returns the updated route' do
        put "/api/v1/routes/#{route_id}", params: { route: route_params }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to eq('application/json; charset=utf-8')
        expect(JSON.parse(response.body)).to include(route_params)
      end
    end

    context 'when the route does not exist' do
      before do
        allow(ROUTE_COLLECTION).to receive(:upsert).with(route_id, route_params).and_raise(Couchbase::Error::DocumentNotFound)
      end

      it 'returns a not found error' do
        put "/api/v1/routes/#{route_id}", params: { route: route_params }

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Route not found' })
      end
    end
  end

  describe 'DELETE /api/v1/routes/{id}' do
    let(:route_id) { 'route_delete' }

    context 'when the route is deleted successfully' do
      before do
        allow(ROUTE_COLLECTION).to receive(:remove).with(route_id)
      end

      it 'returns a success message' do
        delete "/api/v1/routes/#{route_id}"

        expect(response).to have_http_status(:accepted)
        expect(JSON.parse(response.body)).to eq({ 'message' => 'Route deleted successfully' })
      end
    end

    context 'when the route does not exist' do
      before do
        allow(ROUTE_COLLECTION).to receive(:remove).with(route_id).and_raise(Couchbase::Error::DocumentNotFound)
      end

      it 'returns a not found error' do
        delete "/api/v1/routes/#{route_id}"

        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)).to eq({ 'error' => 'Route not found' })
      end
    end
  end
end
