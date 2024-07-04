require 'swagger_helper'

describe 'Hotels API', type: :request do
  path '/api/v1/hotels/autocomplete' do
    get 'Retrieve suggestion for Hotel names' do
      tags 'Hotels'
      produces 'application/json'
      parameter name: :name, in: :query, type: :string, description: 'name of the hotel'

      response '200', 'Hotels found' do
        schema type: :Array,
               items: {
                 type: :string
               }
        let(:name) { 'air' }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length()).to be >(0)
        end
      end

      response '200', 'No suggestion' do
        schema type: :Array,
               items: {
                 type: :string
               }
        let(:name) { 'ggg' }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length()).to eq(0)
        end
      end
    end
  end

  path '/api/v1/hotels/filter' do
    post 'Hotel search filter' do
      tags 'Hotels'
      consumes 'application/json'
      produces 'application/json'
      parameter name: :hotel, in: :body, schema: {
        type: :object,
        properties: {
          name: { type: :string },
          title: { type: :string },
          description: { type: :string },
          country: { type: :string },
          city: { type: :string },
          state: { type: :string }
        }
      }, description: 'hotel filter'

      response '200', 'Hotels found' do
        schema type: :Array,
               items: {
                 type: :object,
                 properties: {
                   name: { type: :string },
                   title: { type: :string },
                   description: { type: :string },
                   country: { type: :string },
                   city: { type: :string, nullable: true},
                   state: { type: :string, nullable: true}
                 },
                 required: %w[name title description]
               }
        let(:hotel) { {description: "newly renovated"} }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length()).to be >(0)
        end
      end
      response '200', 'only one Hotels found' do
        schema type: :Array,
               items: {
                 type: :object,
                 properties: {
                   name: { type: :string },
                   title: { type: :string },
                   description: { type: :string },
                   country: { type: :string },
                   city: { type: :string, nullable: true},
                   state: { type: :string, nullable: true}
                 },
                 required: %w[name title description]
               }
        let(:hotel) { { "name": "Sheraton Fisherman's Wharf" } }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length()).to eq(1)
        end
      end
      response '200', 'only one Hotels found' do
        schema type: :Array,
               items: {
                 type: :object,
                 properties: {
                   name: { type: :string },
                   title: { type: :string },
                   description: { type: :string },
                   country: { type: :string },
                   city: { type: :string, nullable: true},
                   state: { type: :string, nullable: true}
                 },
                 required: %w[name title description]
               }
        let(:hotel) { {
          "name": "Sheraton Fisherman's Wharf",
          "title": "San Francisco/Fisherman's Wharf",
          "description": "This hotel is newly renovated and centrally located.",
          "country": "United States",
          "city": "San Francisco",
          "state": "California"
        } }
        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data.length()).to eq(1)
        end
      end
    end
  end
end
