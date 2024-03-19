class Airline
  attr_accessor :id
  attr_accessor :name
  attr_accessor :iata
  attr_accessor :icao
  attr_accessor :callsign
  attr_accessor :country

  def initialize(attributes)
    @id = attributes['id']
    @name = attributes['name']
    @iata = attributes['iata']
    @icao = attributes['icao']
    @callsign = attributes['callsign']
    @country = attributes['country']
  end

  def self.find(id)
    result = AIRLINE_COLLECTION.get(id)
    new(result.content) if result.success?
  rescue Couchbase::Error::DocumentNotFound
    nil
  end

  def self.all(country = nil)
    query = country ? "SELECT * FROM #{AIRLINE_COLLECTION.name} WHERE country = $country" : "SELECT * FROM #{AIRLINE_COLLECTION.name}"
    params = country ? { "$country" => country } : {}
    result = AIRLINE_COLLECTION.query(query, params)
    result.rows.map { |row| new(row) }
  end

  def self.to_airport(destination_airport_code)
    query = "
      SELECT air.*
      FROM #{ROUTE_COLLECTION.name} AS r
      JOIN #{AIRLINE_COLLECTION.name} AS air ON r.airlineId = air.id
      WHERE r.destinationAirport = $airport
    "
    params = { "$airport" => destination_airport_code }
    result = ROUTE_COLLECTION.query(query, params)
    result.rows.map { |row| new(row) }
  end

  def self.create(attributes)
    id = AIRLINE_COLLECTION.insert(attributes)
    new(attributes.merge(id: id))
  rescue Couchbase::Error::DocumentExists
    nil
  end

  def update(attributes)
    AIRLINE_COLLECTION.upsert(id, attributes)
    self.class.new(attributes)
  rescue Couchbase::Error::DocumentNotFound
    nil
  end

  def destroy
    AIRLINE_COLLECTION.remove(id)
    true
  rescue Couchbase::Error::DocumentNotFound
    false
  end
end
