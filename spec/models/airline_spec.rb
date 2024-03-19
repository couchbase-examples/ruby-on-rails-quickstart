# spec/models/airline_spec.rb
require 'rails_helper'

RSpec.describe Airline, type: :model do
  describe '.find' do
    it 'retrieves an airline by ID' do
      airline_id = 'airline_123'
      airline_attributes = { 'id' => airline_id, 'name' => 'Acme Air' }
      allow(AIRLINE_COLLECTION).to receive(:get).with(airline_id).and_return(double(success?: true, content: airline_attributes))

      airline = Airline.find(airline_id)

      expect(airline).to be_an_instance_of(Airline)
      expect(airline.id).to eq(airline_id)
      expect(airline.name).to eq('Acme Air')
    end

    it 'returns nil when airline is not found' do
      airline_id = 'nonexistent_airline'
      allow(AIRLINE_COLLECTION).to receive(:get).with(airline_id).and_raise(Couchbase::Error::DocumentNotFound)

      airline = Airline.find(airline_id)

      expect(airline).to be_nil
    end
  end

  describe '.all' do
    it 'retrieves all airlines' do
      airline_attributes = [
        { 'id' => 'airline_1', 'name' => 'Airline 1' },
        { 'id' => 'airline_2', 'name' => 'Airline 2' }
      ]
      allow(AIRLINE_COLLECTION).to receive(:query).and_return(double(rows: airline_attributes))

      airlines = Airline.all

      expect(airlines.length).to eq(2)
      expect(airlines.first).to be_an_instance_of(Airline)
      expect(airlines.first.id).to eq('airline_1')
      expect(airlines.first.name).to eq('Airline 1')
    end

    it 'retrieves airlines by country' do
      country = 'United States'
      airline_attributes = [
        { 'id' => 'airline_1', 'name' => 'Airline 1', 'country' => 'United States' },
        { 'id' => 'airline_2', 'name' => 'Airline 2', 'country' => 'United States' }
      ]
      allow(AIRLINE_COLLECTION).to receive(:query).with(/WHERE country = \$country/, "$country" => country).and_return(double(rows: airline_attributes))

      airlines = Airline.all(country)

      expect(airlines.length).to eq(2)
      expect(airlines.first).to be_an_instance_of(Airline)
      expect(airlines.first.id).to eq('airline_1')
      expect(airlines.first.name).to eq('Airline 1')
      expect(airlines.first.country).to eq('United States')
    end
  end

  describe '.to_airport' do
    it 'retrieves airlines flying to a destination airport' do
      destination_airport_code = 'JFK'
      airline_attributes = [
        { 'id' => 'airline_1', 'name' => 'Airline 1' },
        { 'id' => 'airline_2', 'name' => 'Airline 2' }
      ]
      allow(ROUTE_COLLECTION).to receive(:query).with(/WHERE r.destinationAirport = \$airport/, "$airport" => destination_airport_code).and_return(double(rows: airline_attributes))

      airlines = Airline.to_airport(destination_airport_code)

      expect(airlines.length).to eq(2)
      expect(airlines.first).to be_an_instance_of(Airline)
      expect(airlines.first.id).to eq('airline_1')
      expect(airlines.first.name).to eq('Airline 1')
    end
  end

  describe '.create' do
    it 'creates a new airline' do
      attributes = { 'name' => 'New Airline' }
      allow(AIRLINE_COLLECTION).to receive(:insert).with(attributes).and_return('new_airline_id')

      airline = Airline.create(attributes)

      expect(airline).to be_an_instance_of(Airline)
      expect(airline.id).to eq('new_airline_id')
      expect(airline.name).to eq('New Airline')
    end

    it 'returns nil when airline already exists' do
      attributes = { 'name' => 'Existing Airline' }
      allow(AIRLINE_COLLECTION).to receive(:insert).with(attributes).and_raise(Couchbase::Error::DocumentExists)

      airline = Airline.create(attributes)

      expect(airline).to be_nil
    end
  end

  describe '#update' do
    it 'updates an airline' do
      airline = Airline.new('id' => 'airline_123', 'name' => 'Old Name')
      updated_attributes = { 'name' => 'New Name' }
      allow(AIRLINE_COLLECTION).to receive(:upsert).with('airline_123', updated_attributes)

      updated_airline = airline.update(updated_attributes)

      expect(updated_airline).to be_an_instance_of(Airline)
      expect(updated_airline.id).to eq('airline_123')
      expect(updated_airline.name).to eq('New Name')
    end

    it 'returns nil when airline is not found' do
      airline = Airline.new('id' => 'nonexistent_airline')
      updated_attributes = { 'name' => 'New Name' }
      allow(AIRLINE_COLLECTION).to receive(:upsert).with('nonexistent_airline', updated_attributes).and_raise(Couchbase::Error::DocumentNotFound)

      updated_airline = airline.update(updated_attributes)

      expect(updated_airline).to be_nil
    end
  end

  describe '#destroy' do
    it 'destroys an airline' do
      airline = Airline.new('id' => 'airline_123')
      allow(AIRLINE_COLLECTION).to receive(:remove).with('airline_123')

      result = airline.destroy

      expect(result).to be true
    end

    it 'returns false when airline is not found' do
      airline = Airline.new('id' => 'nonexistent_airline')
      allow(AIRLINE_COLLECTION).to receive(:remove).with('nonexistent_airline').and_raise(Couchbase::Error::DocumentNotFound)

      result = airline.destroy

      expect(result).to be false
    end
  end
end