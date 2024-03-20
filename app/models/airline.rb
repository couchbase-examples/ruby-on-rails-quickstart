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

  def self.all(country = nil, limit = 10, offset = 0)
    query = country ? "SELECT * FROM #{AIRLINE_COLLECTION.name} WHERE country = $country LIMIT $limit OFFSET $offset" : "SELECT * FROM #{AIRLINE_COLLECTION.name} LIMIT $limit OFFSET $offset"
    params = country ? { "$country" => country, "$limit" => limit.to_i, "$offset" => offset.to_i } : { "$limit" => limit.to_i, "$offset" => offset.to_i }
    result = COUCHBASE_CLUSTER.query(query, params)
    result.rows.map { |row| new(row) }
  end

  def self.to_airport(destination_airport_code, limit = 10, offset = 0)
    query = "
      SELECT air.callsign,
             air.country,
             air.iata,
             air.icao,
             air.id,
             air.name,
             air.type
      FROM (SELECT DISTINCT META(airline).id AS airlineId
            FROM route
            JOIN airline
            ON route.airlineid = META(airline).id
            WHERE route.destinationairport = $airport) AS subquery
      JOIN airline AS air
      ON META(air).id = subquery.airlineId
      LIMIT $limit OFFSET $offset
    "
    params = { "$airport" => destination_airport_code, "$limit" => limit.to_i, "$offset" => offset.to_i }
    result = COUCHBASE_CLUSTER.query(query, params)
    result.rows.map { |row| new(row) }
  end

  def self.create(attributes)
    id = AIRLINE_COLLECTION.insert(attributes)
    new(attributes.merge(id: id))
  rescue Couchbase::Error::DocumentExistsError
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
