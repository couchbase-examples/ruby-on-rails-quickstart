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
    bucket_name = 'travel-sample'
    scope_name = 'inventory'
    collection_name = 'airline'

    query = country ? "SELECT * FROM `#{bucket_name}`.`#{scope_name}`.`#{collection_name}` WHERE country = $country LIMIT $limit OFFSET $offset" : "SELECT * FROM `#{bucket_name}`.`#{scope_name}`.`#{collection_name}` LIMIT $limit OFFSET $offset"
    options = Couchbase::Cluster::QueryOptions.new
    options.named_parameters(country ? { "country" => country, "limit" => limit.to_i, "offset" => offset.to_i } : { "limit" => limit.to_i, "offset" => offset.to_i })

    result = COUCHBASE_CLUSTER.query(query, options)
    result.rows.map { |row| new(row.fetch('airline', {})) }.to_a
  end

  def self.to_airport(destination_airport_code, limit = 10, offset = 0)
    bucket_name = 'travel-sample'
    scope_name = 'inventory'
    route_collection_name = 'route'
    airline_collection_name = 'airline'

    query = "
      SELECT air.callsign, air.country, air.iata, air.icao, air.id, air.name
      FROM (SELECT DISTINCT META(#{airline_collection_name}).id AS airlineId
            FROM `#{bucket_name}`.`#{scope_name}`.`#{route_collection_name}` AS route
            JOIN `#{bucket_name}`.`#{scope_name}`.`#{airline_collection_name}` AS airline
            ON route.airlineid = META(airline).id
            WHERE route.destinationairport = $airport) AS subquery
      JOIN `#{bucket_name}`.`#{scope_name}`.`#{airline_collection_name}` AS air
      ON META(air).id = subquery.airlineId
      LIMIT $limit OFFSET $offset
    "

    options = Couchbase::Cluster::QueryOptions.new
    options.named_parameters({ "airport" => destination_airport_code, "limit" => limit.to_i, "offset" => offset.to_i })

    result = COUCHBASE_CLUSTER.query(query, options)
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
