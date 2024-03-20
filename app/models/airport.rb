class Airport
  attr_accessor :id
  attr_accessor :type
  attr_accessor :airportname
  attr_accessor :city
  attr_accessor :country
  attr_accessor :faa
  attr_accessor :icao
  attr_accessor :tz
  attr_accessor :geo

  def initialize(attributes)
    @id = attributes['id']
    @type = attributes['type']
    @airportname = attributes['airportname']
    @city = attributes['city']
    @country = attributes['country']
    @faa = attributes['faa']
    @icao = attributes['icao']
    @tz = attributes['tz']
    @geo = attributes['geo']
  end

  def self.find(id)
    result = AIRPORT_COLLECTION.get(id)
    new(result.content) if result.success?
  rescue Couchbase::Error::DocumentNotFound
    nil
  end

  def self.create(attributes)
    id = AIRPORT_COLLECTION.insert(attributes)
    new(attributes.merge(id: id))
  rescue Couchbase::Error::DocumentExistsError
    nil
  end

  def update(attributes)
    AIRPORT_COLLECTION.upsert(id, attributes)
    self.class.new(attributes)
  rescue Couchbase::Error::DocumentNotFound
    nil
  end

  def destroy
    AIRPORT_COLLECTION.remove(id)
    true
  rescue Couchbase::Error::DocumentNotFound
    false
  end

  def self.direct_connections(destination_airport_code, limit = 10, offset = 0)
    bucket_name = 'travel-sample'
    scope_name = 'inventory'
    route_collection_name = 'route'
    airport_collection_name = 'airport'

    query = "
      SELECT DISTINCT route.destinationairport
      FROM `#{bucket_name}`.`#{scope_name}`.`#{airport_collection_name}` AS airport
      JOIN `#{bucket_name}`.`#{scope_name}`.`#{route_collection_name}` AS route ON route.sourceairport = airport.faa
      WHERE airport.faa = $destinationAirportCode AND route.stops = 0
      LIMIT $limit OFFSET $offset
    "

    options = Couchbase::Cluster::QueryOptions.new
    options.named_parameters({ "destinationAirportCode" => destination_airport_code, "limit" => limit.to_i, "offset" => offset.to_i })

    result = COUCHBASE_CLUSTER.query(query, options)
    result.rows.map { |row| row['destinationairport'] }
  end
end
