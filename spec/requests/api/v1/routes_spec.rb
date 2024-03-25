require 'swagger_helper'

describe 'Routes API', type: :request  do
  path '/api/v1/routes/{id}' do
    get 'Retrieves a route by ID' do
      tags 'Routes'
      produces 'application/json'
      parameter name: :id, in: :path, type: :string, description: 'ID of the route'

      response '200', 'route found' do
        schema type: :object,
          properties: {
            id: { type: :integer },
            type: { type: :string },
            airline: { type: :string },
            airlineid: { type: :string },
            sourceairport: { type: :string },
            destinationairport: { type: :string },
            stops: { type: :integer },
            equipment: { type: :string },
            schedule: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  day: { type: :integer },
                  flight: { type: :string },
                  utc: { type: :string }
                }
              }
            },
            distance: { type: :number }
          },
          required: ['id', 'type']

        let(:id) { 'route_10209' }
        run_test!
      end

      response '404', 'route not found' do
        let(:id) { 'invalid_id' }
        run_test!
      end
    end

    post 'Creates a route' do
      tags 'Routes'
      consumes 'application/json'
      parameter name: :id, in: :path, type: :string, description: 'ID of the route'
      parameter name: :route, in: :body, schema: {
        type: :object,
        properties: {
          id: { type: :integer },
          type: { type: :string },
          airline: { type: :string },
          airlineid: { type: :string },
          sourceairport: { type: :string },
          destinationairport: { type: :string },
          stops: { type: :integer },
          equipment: { type: :string },
          schedule: {
            type: :array,
            items: {
              type: :object,
              properties: {
                day: { type: :integer },
                flight: { type: :string },
                utc: { type: :string }
              }
            }
          },
          distance: { type: :number }
        },
        required: ['id', 'type']
      }

      response '201', 'route created' do
        let(:route) do
          {
            id: 10001,
            type: 'route',
            airline: 'AF',
            airlineid: 'airline_137',
            sourceairport: 'TLV',
            destinationairport: 'MRS',
            stops: 0,
            equipment: '320',
            schedule: [
              { day: 0, utc: '10:13:00', flight: 'AF198' },
              { day: 0, utc: '19:14:00', flight: 'AF547' }
            ],
            distance: 2881.617376098415
          }
        end
        run_test!
      end

      response '422', 'invalid request' do
        let(:route) { { id: 10001 } }
        run_test!
      end
    end

    put 'Updates a route' do
      tags 'Routes'
      consumes 'application/json'
      parameter name: :id, in: :path, type: :string, description: 'ID of the route'
      parameter name: :route, in: :body, schema: {
        type: :object,
        properties: {
          airline: { type: :string },
          airlineid: { type: :string },
          sourceairport: { type: :string },
          destinationairport: { type: :string },
          stops: { type: :integer },
          equipment: { type: :string },
          schedule: {
            type: :array,
            items: {
              type: :object,
              properties: {
                day: { type: :integer },
                flight: { type: :string },
                utc: { type: :string }
              }
            }
          },
          distance: { type: :number }
        }
      }

      response '200', 'route updated' do
        let(:id) { 'route_10209' }
        let(:route) { { stops: 1 } }
        run_test!
      end

      response '404', 'route not found' do
        let(:id) { 'invalid_id' }
        let(:route) { { stops: 1 } }
        run_test!
      end
    end

    delete 'Deletes a route' do
      tags 'Routes'
      parameter name: :id, in: :path, type: :string, description: 'ID of the route'

      response '204', 'route deleted' do
        let(:id) { 'route_10209' }
        run_test!
      end

      response '404', 'route not found' do
        let(:id) { 'invalid_id' }
        run_test!
      end
    end
  end
end